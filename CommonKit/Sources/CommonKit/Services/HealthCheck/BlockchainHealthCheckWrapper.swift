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

public final class BlockchainHealthCheckWrapper<
    Service: BlockchainHealthCheckableService
>: HealthCheckWrapper<Service, Service.Error> {
    private let nodesStorage: NodesStorageProtocol
    private let updateNodesAvailabilityLock = NSLock()
    private let params: BlockchainHealthCheckParams
    
    @Atomic private var currentRequests = Set<UUID>()
    
    public init(
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
        
        nodesAdditionalParamsStorage
            .fastestNodeMode(group: params.group)
            .sink { [weak self] in self?.fastestNodeMode = $0 }
            .store(in: &subscriptions)
    }
    
    public override func healthCheck() {
        super.healthCheck()
        guard isActive else { return }
        
        Task {
            updateNodesAvailability(update: nil)
            
            await withTaskGroup(of: Void.self, returning: Void.self) { group in
                nodes.filter { $0.isEnabled }.forEach { node in
                    group.addTask { [weak self] in
                        guard
                            let self = self,
                            let update = await updateNodeStatusInfo(node: node)
                        else { return }
                        
                        updateNodesAvailability(update: update)
                    }
                }
                
                await group.waitForAll()
            }
        }
    }
}

private extension BlockchainHealthCheckWrapper {
    struct NodeUpdate {
        let id: UUID
        let info: NodeStatusInfo?
        let preferMainOrigin: Bool?
    }
    
    func updateNodeStatusInfo(node: Node) async -> NodeUpdate? {
        guard !currentRequests.contains(node.id) else { return nil }
        currentRequests.insert(node.id)
        defer { currentRequests.remove(node.id) }
        
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
        updateNodesAvailabilityLock.lock()
        defer { updateNodesAvailabilityLock.unlock() }
        
        if let update = update {
            applyUpdate(update: update)
        }
        
        let workingNodes = nodes.filter {
            $0.isEnabled && ($0.isWorkingStatus)
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
                    : .synchronizing
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
