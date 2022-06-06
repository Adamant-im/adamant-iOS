//
//  AdamantHealthCheckService.swift
//  Adamant
//
//  Created by Андрей on 06.06.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import Foundation

final class AdamantHealthCheckService: HealthCheckService {
    // MARK: - Dependencies
    
    var apiService: ApiService!
    
    // MARK: - Tools
    
    func healthCheck(
        nodes: [Node],
        firstWorkingNodeHandler: @escaping (Node) -> Void,
        allowedNodesHandler: @escaping ([Node]) -> Void
    ) {
        let group = DispatchGroup()
        var workingNodes = [Node]()
        var firstWorkingNodeWasFound = false

        nodes.forEach { node in
            group.enter()
            testNode(node: node) { isSuccess in
                defer { group.leave() }

                guard isSuccess else { return }
                workingNodes.append(node)

                guard !firstWorkingNodeWasFound else { return }
                firstWorkingNodeWasFound = true
                firstWorkingNodeHandler(node)
            }
        }

        group.notify(queue: .global(qos: .utility)) {
            allowedNodesHandler(
                getAllowedNodesSortedByPingAscending(nodes: workingNodes)
            )
        }
    }
    
    func testNode(
        node: Node,
        completion: @escaping (Bool) -> Void
    ) {
        guard let nodeURL = node.asURL() else {
            completion(false)
            return
        }
        
        let startTimestamp = Date().timeIntervalSince1970
        
        apiService.getNodeStatus(url: nodeURL) { result in
            switch result {
            case let .success(status):
                node.ping = Date().timeIntervalSince1970 - startTimestamp
                node.height = status.network?.height
                node.wsEnabled = status.wsClient?.enabled
                
                completion(node.height != nil && node.wsEnabled ?? false)
            case .failure:
                completion(false)
            }
        }
    }
}

private func getAllowedNodesSortedByPingAscending(nodes: [Node]) -> [Node] {
    guard
        let actualHeightsRange = getActualNodeHeightsRange(
            heights: nodes.compactMap { $0.height }
        )
    else {
        return []
    }
    
    return nodes
        .filter {
            guard let height = $0.height else { return false }
            return actualHeightsRange.contains(height)
        }
        .sorted { $0.ping ?? .greatestFiniteMagnitude < $1.ping ?? .greatestFiniteMagnitude }
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
