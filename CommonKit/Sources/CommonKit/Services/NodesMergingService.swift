//
//  AdamantNodesMergingService.swift
//  Adamant
//
//  Created by Andrew G on 02.08.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

public struct NodesMergingService: NodesMergingServiceProtocol {
    public func merge(
        savedNodes: [NodeGroup: [Node]],
        defaultNodes: [NodeGroup: [Node]]
    ) -> [NodeGroup: [Node]] {
        var resultNodes = savedNodes
        
        defaultNodes.keys.forEach { group in
            guard resultNodes[group] == nil else { return }
            resultNodes[group] = .init()
        }
        
        resultNodes.forEach { group, nodes in
            guard let defaultNodes = defaultNodes[group] else { return }
            resultNodes[group] = merge(savedNodes: nodes, defaultNodes: defaultNodes)
        }
        
        return resultNodes
    }
    
    public init() {}
}

private extension NodesMergingService {
    func merge(savedNodes: [Node], defaultNodes: [Node]) -> [Node] {
        var resultNodes = savedNodes
        var defaultNodes = defaultNodes
        var removedNodesIndexes: [Int] = .init()
        
        // Merging default nodes
        resultNodes.enumerated().forEach { index, node in
            switch node.type {
            case .default:
                let defaultNodeIndex = defaultNodes.firstIndex { $0.isSame(node) }
                
                if let defaultNodeIndex = defaultNodeIndex {
                    resultNodes[index].merge(defaultNodes[defaultNodeIndex])
                    defaultNodes.remove(at: defaultNodeIndex)
                } else {
                    // If the default node saved, but not persists in the defaultNodes list,
                    // it has to be removed
                    removedNodesIndexes.append(index)
                }
            case .custom:
                break
            }
        }
        
        removedNodesIndexes.reversed().forEach {
            resultNodes.remove(at: $0)
        }
        
        // We are filtering default nodes to avoid duplications.
        // Maybe a new default node is a user's old custom node
        return resultNodes + defaultNodes.filter { defaultNode in
            !resultNodes.contains { $0.isSame(defaultNode) }
        }
    }
}

private extension Node {
    mutating func merge(_ node: Node) {
        mainOrigin.merge(node.mainOrigin)
        
        guard let mergedAltOrigin = node.altOrigin else {
            altOrigin = nil
            return
        }
        
        guard altOrigin != nil else {
            altOrigin = mergedAltOrigin
            return
        }
        
        altOrigin?.merge(mergedAltOrigin)
    }
}

private extension NodeOrigin {
    mutating func merge(_ origin: NodeOrigin) {
        scheme = origin.scheme
        host = origin.host
        port = origin.port
        origin.wsPort.map { wsPort = $0 }
    }
}
