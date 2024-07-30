//
//  BlockchainHealthCheckWrapper.swift
//  Adamant
//
//  Created by Andrew G on 22.10.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import CommonKit
import Foundation

protocol BlockchainHealthCheckableService {
    associatedtype Error: HealthCheckableError
    
    func getStatusInfo(origin: NodeOrigin) async -> Result<NodeStatusInfo, Error>
}

final class BlockchainHealthCheckWrapper<
    Service: BlockchainHealthCheckableService
>: HealthCheckWrapper<Service, Service.Error> {
    private let nodesStorage: NodesStorageProtocol
    private let updateNodesAvailabilityLock = NSLock()
    
    @Atomic private var currentRequests = Set<UUID>()
    
    init(
        service: Service,
        nodesStorage: NodesStorageProtocol,
        nodesAdditionalParamsStorage: NodesAdditionalParamsStorageProtocol,
        nodeGroup: NodeGroup
    ) {
        self.nodesStorage = nodesStorage
        
        super.init(
            service: service,
            normalUpdateInterval: nodeGroup.normalUpdateInterval,
            crucialUpdateInterval: nodeGroup.crucialUpdateInterval,
            nodeGroup: nodeGroup
        )
        
        nodesStorage
            .getNodesPublisher(group: nodeGroup)
            .sink { [weak self] in self?.nodes = $0 }
            .store(in: &subscriptions)
        
        nodesAdditionalParamsStorage
            .fastestNodeMode(group: nodeGroup)
            .sink { [weak self] in self?.fastestNodeMode = $0 }
            .store(in: &subscriptions)
    }
    
    override func healthCheck() {
        super.healthCheck()
        
        Task {
            updateNodesAvailability()
            await withTaskGroup(of: Void.self, returning: Void.self) { group in
                nodes.filter { $0.isEnabled }.forEach { node in
                    group.addTask { [weak self] in
                        await self?.updateNodeStatusInfo(node: node)
                    }
                }
                
                await group.waitForAll()
            }
        }
    }
}

private extension BlockchainHealthCheckWrapper {
    func updateNodeStatusInfo(node: Node) async {
        guard !currentRequests.contains(node.id) else { return }
        currentRequests.insert(node.id)
        var forceInclude: UUID?
        
        defer {
            currentRequests.remove(node.id)
            updateNodesAvailability(forceInclude: forceInclude)
        }
        
        guard node.preferMainOrigin == nil else {
            switch await updateNodeStatusInfo(
                id: node.id,
                origin: node.preferredOrigin,
                markAsOfflineIfFailed: true
            ) {
            case .success:
                forceInclude = node.id
            case .failure, .none:
                break
            }
            
            return
        }
        
        switch await updateNodeStatusInfo(
            id: node.id,
            origin: node.mainOrigin,
            markAsOfflineIfFailed: false
        ) {
        case .success:
            nodesStorage.updateNode(id: node.id) { $0.preferMainOrigin = true }
            forceInclude = node.id
        case .failure:
            switch await updateNodeStatusInfo(
                id: node.id,
                origin: node.mainOrigin,
                markAsOfflineIfFailed: true
            ) {
            case .success:
                nodesStorage.updateNode(id: node.id) { $0.preferMainOrigin = false }
                forceInclude = node.id
            case .failure, .none:
                break
            }
        case .none:
            break
        }
    }
    
    @discardableResult
    func updateNodeStatusInfo(
        id: UUID,
        origin: NodeOrigin,
        markAsOfflineIfFailed: Bool
    ) async -> Result<Void, Error>? {
        switch await service.getStatusInfo(origin: origin) {
        case let .success(info):
            applyStatusInfo(id: id, info: info)
            return .success(())
        case let .failure(error):
            guard !error.isRequestCancelledError else { return nil }
            
            if markAsOfflineIfFailed {
                nodesStorage.updateNode(id: id) { $0.connectionStatus = .offline }
            }
            
            return .failure(error)
        }
    }
    
    func applyStatusInfo(id: UUID, info: NodeStatusInfo) {
        nodesStorage.updateNode(id: id) { node in
            node.wsEnabled = info.wsEnabled
            node.updateWsPort(info.wsPort)
            node.version = info.version
            node.height = info.height
            node.ping = info.ping
            
            guard
                let versionNumber = Node.stringToDouble(info.version),
                versionNumber < nodeGroup.minNodeVersion
            else { return }
            
            node.connectionStatus = .notAllowed(.outdatedApiVersion)
        }
    }
    
    func updateNodesAvailability(forceInclude: UUID? = nil) {
        updateNodesAvailabilityLock.lock()
        defer { updateNodesAvailabilityLock.unlock() }
        
        let workingNodes = nodes.filter {
            $0.isEnabled && ($0.isWorkingStatus || $0.id == forceInclude)
        }
        
        let actualHeightsRange = getActualNodeHeightsRange(
            heights: workingNodes.compactMap { $0.height },
            group: nodeGroup
        )
        
        workingNodes.forEach { node in
            var status: NodeConnectionStatus?
            let actualNodeVersion = Node.stringToDouble(node.version)
            
            if let actualNodeVersion = actualNodeVersion,
               actualNodeVersion < nodeGroup.minNodeVersion {
                status = .notAllowed(.outdatedApiVersion)
            } else {
                status = node.height.map { height in
                    actualHeightsRange?.contains(height) ?? false
                    ? .allowed
                    : .synchronizing
                } ?? .none
            }
            
            nodesStorage.updateNode(id: node.id) { $0.connectionStatus = status }
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

private func getActualNodeHeightsRange(heights: [Int], group: NodeGroup) -> ClosedRange<Int>? {
    let heights = heights.sorted()
    var bestInterval: NodeHeightsInterval?
    
    for i in heights.indices {
        var currentInterval = NodeHeightsInterval(
            range: heights[i] ... heights[i] + group.nodeHeightEpsilon - 1,
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
