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
    
    func getStatusInfo(node: Node) async -> Result<NodeStatusInfo, Error>
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
                        guard let self = self, !currentRequests.contains(node.id) else { return }
                        await updateNodeStatusInfo(node: node)
                    }
                }
                
                await group.waitForAll()
            }
        }
    }
}

private extension BlockchainHealthCheckWrapper {
    func updateNodeStatusInfo(node: Node) async {
        currentRequests.insert(node.id)
        defer { currentRequests.remove(node.id) }
        
        let statusInfo = await service.getStatusInfo(node: node)
        nodesStorage.updateNodeStatus(id: node.id, statusInfo: try? statusInfo.get())
        
        switch statusInfo {
        case .success(let info):
            if let versionNumber = Node.stringToDouble(info.version),
               versionNumber < nodeGroup.minNodeVersion {
                nodesStorage.updateNodeParams(
                    id: node.id,
                    connectionStatus: .notAllowed(.outdatedApiVersion)
                )
            }
            
            updateNodesAvailability(forceInclude: node.id)
        case let .failure(error):
            guard !error.isRequestCancelledError else { return }
            nodesStorage.updateNodeParams(id: node.id, connectionStatus: .offline)
            updateNodesAvailability()
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
            var status: Node.ConnectionStatus?
            let actualNodeVersion = Node.stringToDouble(node.version)
            
            if let actualNodeVersion = actualNodeVersion,
               actualNodeVersion < nodeGroup.minNodeVersion {
                status = Node.ConnectionStatus.notAllowed(.outdatedApiVersion)
            } else {
                status = node.height.map { height in
                    actualHeightsRange?.contains(height) ?? false
                    ? .allowed
                    : .synchronizing
                } ?? .none
            }
            
            nodesStorage.updateNodeParams(
                id: node.id,
                connectionStatus: status
            )
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
