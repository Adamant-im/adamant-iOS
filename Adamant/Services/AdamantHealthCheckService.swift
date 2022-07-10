//
//  AdamantHealthCheckService.swift
//  Adamant
//
//  Created by Андрей on 06.06.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import Foundation
import Alamofire

final class AdamantHealthCheckService: HealthCheckService {
    // MARK: - Dependencies
    
    var apiService: ApiService!
    
    // MARK: - Properties
    
    var nodes = [Node]() {
        didSet {
            healthCheckIndex += 1
        }
    }
    
    weak var delegate: HealthCheckDelegate?
    private var healthCheckIndex = 0
    
    // MARK: - Tools
    
    func getPreferredNode(fastest: Bool, needWS: Bool) -> Node? {
        let allowedNodes = nodes.filter {
            $0.connectionStatus == .allowed
                && (!needWS || $0.status?.wsEnabled ?? false)
        }
        
        let nodesForChoosing = allowedNodes.isEmpty && !needWS
            ? nodes.filter { $0.isEnabled && $0.connectionStatus != .offline }
            : allowedNodes
        
        return fastest
            ? nodesForChoosing.min {
                $0.status?.ping ?? .greatestFiniteMagnitude
                    < $1.status?.ping ?? .greatestFiniteMagnitude
            }
            : nodesForChoosing.random
    }
    
    func healthCheck() {
        let healthCheckIndex = healthCheckIndex + 1
        self.healthCheckIndex = healthCheckIndex
        updateNodesAvailability()

        nodes.filter { $0.isEnabled }.forEach { node in
            updateNodeStatus(node: node, healthCheckIndex: healthCheckIndex)
        }
    }
    
    private func updateNodesAvailability() {
        let workingNodes = nodes.filter { $0.isWorking }
        
        let actualHeightsRange = getActualNodeHeightsRange(
            heights: workingNodes.compactMap { $0.status?.height }
        )
        
        for node in workingNodes {
            node.connectionStatus = node.status?.height.map { height in
                actualHeightsRange?.contains(height) ?? false
                    ? .allowed
                    : .synchronizing
            } ?? .synchronizing
        }
        
        delegate?.healthCheckUpdate()
    }
    
    private func updateNodeStatus(node: Node, healthCheckIndex: Int) {
        guard let nodeURL = node.asURL() else {
            node.connectionStatus = .offline
            node.status = nil
            return
        }
        
        let startTimestamp = Date().timeIntervalSince1970
        
        apiService.getNodeStatus(url: nodeURL) { [weak self] result in
            guard healthCheckIndex == self?.healthCheckIndex else { return }
            
            switch result {
            case let .success(status):
                node.status = Node.Status(
                    status: status,
                    ping: Date().timeIntervalSince1970 - startTimestamp
                )
                if !node.isWorking {
                    node.connectionStatus = .synchronizing
                }
            case .failure:
                node.connectionStatus = .offline
                node.status = nil
            }
            
            self?.updateNodesAvailability()
        }
    }
}

private extension Node {
    var isWorking: Bool {
        switch connectionStatus {
        case .allowed, .synchronizing:
            return true
        case .offline, .none:
            return false
        }
    }
}

private extension Node.Status {
    init(status: NodeStatus, ping: TimeInterval) {
        self.init(
            ping: ping,
            wsEnabled: status.wsClient?.enabled ?? false,
            height: status.network?.height,
            version: status.version?.version
        )
    }
}

private func getActualNodeHeightsRange(heights: [Int]) -> ClosedRange<Int>? {
    struct NodeHeightsInterval {
        let range: ClosedRange<Int>
        var count: Int
    }
    
    let heights = heights.sorted()
    var bestInterval: NodeHeightsInterval?
    
    for i in heights.indices {
        var currentInterval = NodeHeightsInterval(
            range: heights[i] - nodeHeightEpsilon ... heights[i] + nodeHeightEpsilon,
            count: 1
        )
        
        for j in stride(from: i + 1, to: heights.endIndex, by: 1) {
            guard currentInterval.range.contains(heights[j]) else { break }
            currentInterval.count += 1
        }
        
        for j in stride(from: i - 1, through: 0, by: -1) {
            guard currentInterval.range.contains(heights[j]) else { break }
            currentInterval.count += 1
        }
        
        if currentInterval.count >= bestInterval?.count ?? 0 {
            bestInterval = currentInterval
        }
        
        if bestInterval?.count ?? 0 >= heights.count - i {
            break
        }
    }
    
    return bestInterval?.range
}

private let nodeHeightEpsilon = 10