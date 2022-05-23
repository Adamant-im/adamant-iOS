//
//  AdamantApi+HealthCheck.swift
//  Adamant
//
//  Created by Андрей on 22.05.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import Foundation

private struct NodeHeightsInterval {
    let range: ClosedRange<Int>
    var count: Int
}

private struct NodeWithPing {
    let node: Node
    let ping: TimeInterval
}

extension AdamantApiService {
    func healthCheck(
        nodes: [Node],
        firstWorkingNodeHandler: @escaping (Node) -> Void,
        allowedNodesHandler: @escaping ([Node]) -> Void
    ) {
        let group = DispatchGroup()
        var workingNodes = [NodeWithPing]()
        var firstWorkingNodeWasFound = false
        
        nodes.forEach { node in
            group.enter()
            testNode(node: node) { result in
                defer { group.leave() }
                
                switch result {
                case .success(let ping):
                    workingNodes.append(NodeWithPing(node: node, ping: ping))
                    
                    guard !firstWorkingNodeWasFound else { return }
                    firstWorkingNodeWasFound = true
                    firstWorkingNodeHandler(node)
                case .failure:
                    break
                }
            }
        }
        
        group.notify(queue: .global(qos: .utility)) {
            allowedNodesHandler(
                getAllowedNodesSortedByPingAscending(nodesWithPings: workingNodes)
            )
        }
    }
}

private func getAllowedNodesSortedByPingAscending(
    nodesWithPings: [NodeWithPing]
) -> [Node] {
    guard
        let actualHeightsRange = getActualNodeHeightsRange(
            heights: nodesWithPings.compactMap { $0.node.height }
        )
    else {
        return []
    }
    
    return nodesWithPings
        .filter {
            guard let height = $0.node.height else { return false }
            return actualHeightsRange.contains(height)
        }
        .sorted { $0.ping < $1.ping }
        .map { $0.node }
}

private func getActualNodeHeightsRange(heights: [Int]) -> ClosedRange<Int>? {
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
