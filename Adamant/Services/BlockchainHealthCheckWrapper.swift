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
        
        defer {
            currentRequests.remove(node.id)
            updateNodesAvailability()
        }
        
        switch await service.getStatusInfo(node: node) {
        case let .success(statusInfo):
            nodesStorage.updateNodeStatus(id: node.id, statusInfo: statusInfo)
            nodesStorage.updateNodeParams(id: node.id, connectionStatus: .some(.none))
        case let .failure(error):
            guard !error.isRequestCancelledError else { return }
            nodesStorage.updateNodeParams(id: node.id, connectionStatus: .offline)
        }
    }
    
    func updateNodesAvailability() {
        let workingNodes = nodes.filter { $0.isWorking }
        
        let actualHeightsRange = getActualNodeHeightsRange(
            heights: workingNodes.compactMap { $0.height },
            group: nodeGroup
        )
        
        workingNodes.forEach { node in
            let status: Node.ConnectionStatus? = node.height.map { height in
                actualHeightsRange?.contains(height) ?? false
                    ? .allowed
                    : .synchronizing
            } ?? .none
            
            nodesStorage.updateNodeParams(
                id: node.id,
                connectionStatus: status
            )
        }
    }
}

private struct NodeHeightsInterval {
    let range: ClosedRange<Int>
    var count: Int
}

private func getActualNodeHeightsRange(heights: [Int], group: NodeGroup) -> ClosedRange<Int>? {
    guard heights.count > 2 else { return heights.max().map { $0...$0 } }
    
    let heights = heights.sorted()
    var bestInterval: NodeHeightsInterval?
    
    for i in heights.indices {
        var currentInterval = NodeHeightsInterval(
            range: heights[i] - group.nodeHeightEpsilon ... heights[i] + group.nodeHeightEpsilon,
            count: 1
        )
        
        for j in stride(from: i + 1, to: heights.endIndex, by: 1) {
            guard currentInterval.range.contains(heights[j]) else { break }
            currentInterval.count += 1
        }
        
        for j in stride(from: i - 1, through: .zero, by: -1) {
            guard currentInterval.range.contains(heights[j]) else { break }
            currentInterval.count += 1
        }
        
        if currentInterval.count >= bestInterval?.count ?? .zero {
            bestInterval = currentInterval
        }
    }
    
    return bestInterval?.range
}
