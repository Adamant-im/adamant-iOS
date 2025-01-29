//
//  BlockchainHealthCheckWrapper.swift
//  Adamant
//
//  Created by Andrew G on 22.10.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation

public protocol BlockchainHealthCheckableService {
    associatedtype Error: HealthCheckableError
    
    func getStatusInfo(origin: NodeOrigin) async -> Result<NodeStatusInfo, Error>
}

@HealthCheckActor
public final class BlockchainHealthCheckWrapper<
    Service: BlockchainHealthCheckableService
>: HealthCheckWrapper<Service, Service.Error>, Sendable {
    private let nodesStorage: NodesStorageProtocol
    private let params: BlockchainHealthCheckParams
    private var currentRequests = Set<UUID>()
    
    nonisolated public init(
        service: Service,
        nodesStorage: NodesStorageProtocol,
        nodesAdditionalParamsStorage: NodesAdditionalParamsStorageProtocol,
        isActive: Bool,
        params: BlockchainHealthCheckParams,
        connection: AnyObservable<Bool>
    ) {
        self.nodesStorage = nodesStorage
        self.params = params
        
        super.init(
            service: service,
            isActive: isActive,
            name: params.name,
            normalUpdateInterval: params.normalUpdateInterval,
            crucialUpdateInterval: params.crucialUpdateInterval,
            connection: connection,
            nodes: nodesStorage.getNodesPublisher(group: params.group)
        )
        
        Task { @HealthCheckActor [self] in
            configure(nodesAdditionalParamsStorage: nodesAdditionalParamsStorage)
        }
    }
    
    public override func healthCheckInternal() async {
        await super.healthCheckInternal()
        updateNodesAvailability(update: nil)
        
        try? await withThrowingTaskGroup(of: Void.self, returning: Void.self) { group in
            nodes.filter { $0.isEnabled }.forEach { node in
                group.addTask { @HealthCheckActor [weak self] in
                    guard let self, !currentRequests.contains(node.id) else { return }
                    
                    currentRequests.insert(node.id)
                    defer { currentRequests.remove(node.id) }
                    
                    let update = await updateNodeStatusInfo(node: node)
                    try Task.checkCancellation()
                    updateNodesAvailability(update: update)
                }
            }
            
            try await group.waitForAll()
            healthCheckPostProcessing()
        }
    }
}

private extension BlockchainHealthCheckWrapper {
    struct NodeUpdate {
        let id: UUID
        let info: NodeStatusInfo?
        let preferMainOrigin: Bool?
    }
    
    func configure(nodesAdditionalParamsStorage: NodesAdditionalParamsStorageProtocol) {
        nodesAdditionalParamsStorage
            .fastestNodeMode(group: params.group)
            .values
            .sink { [weak self] in await self?.setFastestMode($0) }
            .store(in: &subscriptions)
    }
    
    func updateNodeStatusInfo(node: Node) async -> NodeUpdate {
        guard
            node.preferMainOrigin == nil,
            let altOrigin = node.altOrigin
        else {
            return .init(
                id: node.id,
                info: try? await service.getStatusInfo(origin: node.preferredOrigin).get(),
                preferMainOrigin: nil
            )
        }
        
        switch await service.getStatusInfo(origin: node.mainOrigin) {
        case let .success(info):
            return .init(
                id: node.id,
                info: info,
                preferMainOrigin: true
            )
        case .failure:
            switch await service.getStatusInfo(origin: altOrigin) {
            case let .success(info):
                return .init(
                    id: node.id,
                    info: info,
                    preferMainOrigin: false
                )
            case .failure:
                return .init(
                    id: node.id,
                    info: nil,
                    preferMainOrigin: nil
                )
            }
        }
    }
    
    func applyUpdate(update: NodeUpdate) {
        updateNode(id: update.id) { node in
            if let preferMainOrigin = update.preferMainOrigin {
                node.preferMainOrigin = preferMainOrigin
            }
            
            guard let info = update.info else { return node.connectionStatus = .offline }
            node.wsEnabled = info.wsEnabled
            node.updateWsPort(info.wsPort)
            node.version = info.version
            node.height = info.height
            node.ping = info.ping
            
            guard
                let version = info.version,
                let minNodeVersion = params.minNodeVersion,
                version < minNodeVersion
            else { return }
            
            node.connectionStatus = .notAllowed(.outdatedApiVersion)
        }
    }
    
    func updateNodesAvailability(update: NodeUpdate?) {
        let forceIncludeId = update?.info != nil ? update?.id : nil
        
        if let update = update {
            applyUpdate(update: update)
        }
        
        let workingNodes = nodes.filter {
            $0.isEnabled && ($0.isWorkingStatus) || $0.id == forceIncludeId
        }
        
        let actualHeightsRange = getActualNodeHeightsRange(
            heights: workingNodes.compactMap { $0.height },
            group: params.group,
            nodeHeightEpsilon: params.nodeHeightEpsilon
        )
        
        workingNodes.forEach { node in
            var status: NodeConnectionStatus?
            
            if
                let version = node.version,
                let minNodeVersion = params.minNodeVersion,
                version < minNodeVersion
            {
                status = .notAllowed(.outdatedApiVersion)
            } else {
                status = node.height.map { height in
                    actualHeightsRange?.contains(height) ?? false
                        ? .allowed
                        : .synchronizing(isFinal: !node.connectionStatus.notFinalSync)
                } ?? .none
            }
            
            updateNode(id: node.id) { $0.connectionStatus = status }
        }
    }
    
    func updateNode(id: UUID, mutate: (inout Node) -> Void) {
        nodesStorage.updateNode(
            id: id,
            group: params.group,
            mutate: mutate
        )
    }
    
    func healthCheckPostProcessing() {
        nodes.forEach { node in
            guard
                case let .synchronizing(isFinal) = node.connectionStatus,
                !isFinal
            else { return }
            
            updateNode(id: node.id) { $0.connectionStatus = .synchronizing(isFinal: true) }
        }
    }
}

private extension Node {
    var isWorkingStatus: Bool {
        switch connectionStatus {
        case .allowed, .synchronizing, .none:
            return isEnabled
        case .offline, .notAllowed:
            return false
        }
    }
}

private struct NodeHeightsInterval {
    let range: ClosedRange<Int>
    var count: Int
}

private func getActualNodeHeightsRange(
    heights: [Int],
    group: NodeGroup,
    nodeHeightEpsilon: Int
) -> ClosedRange<Int>? {
    let heights = heights.sorted()
    var bestInterval: NodeHeightsInterval?
    
    for i in heights.indices {
        var currentInterval = NodeHeightsInterval(
            range: heights[i] ... heights[i] + nodeHeightEpsilon - 1,
            count: 1
        )
        
        for j in i + 1 ..< heights.endIndex {
            guard currentInterval.range.contains(heights[j]) else { break }
            currentInterval.count += 1
        }
        
        if currentInterval.count >= bestInterval?.count ?? .zero {
            bestInterval = currentInterval
        }
    }
    
    return bestInterval?.range
}

private extension Optional where Wrapped == NodeConnectionStatus {
    var notFinalSync: Bool {
        switch self {
        case .offline, .notAllowed, .none:
            false
        case let .synchronizing(isFinal):
            !isFinal
        case .allowed:
            true
        }
    }
}
