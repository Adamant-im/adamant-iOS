//
//  CoinsNodesListMapper.swift
//  Adamant
//
//  Created by Andrew G on 20.11.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import CommonKit
import SwiftUI

struct CoinsNodesListMapper {
    let processedGroups: Set<NodeGroup>
    
    func map(items: [NodeWithGroup], restNodeIds: [UUID]) -> [CoinsNodesListState.Section] {
        var nodesDict = [NodeGroup: [Node]]()
        
        items.forEach { item in
            guard processedGroups.contains(item.group) else { return }
            
            if nodesDict[item.group] == nil {
                nodesDict[item.group] = [item.node]
            } else {
                nodesDict[item.group]?.append(item.node)
            }
        }
        
        return nodesDict.keys.map {
            map(
                group: $0,
                nodes: nodesDict[$0] ?? .init(),
                restNodeIds: restNodeIds
            )
        }.sorted { $0.title < $1.title }
    }
}

private extension CoinsNodesListMapper {
    func map(
        group: NodeGroup,
        nodes: [Node],
        restNodeIds: [UUID]
    ) -> CoinsNodesListState.Section {
        .init(
            id: group,
            title: group.name,
            rows: nodes.map {
                map(node: $0, restNodeIds: restNodeIds)
            }
        )
    }
    
    func map(node: Node, restNodeIds: [UUID]) -> CoinsNodesListState.Section.Row {
        let indicatorString = node.indicatorString(
            isRest: restNodeIds.contains(node.id),
            isWs: false
        )
        
        var indicatorAttrString = AttributedString(stringLiteral: indicatorString)
        indicatorAttrString.foregroundColor = .init(uiColor: node.indicatorColor)
        
        return .init(
            id: node.id,
            isEnabled: node.isEnabled,
            title: node.asString(),
            connectionStatus: indicatorAttrString,
            description: node.statusString(showVersion: true) ?? .empty
        )
    }
}
