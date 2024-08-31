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
    let processedGroups: [NodeGroup]
    
    func map(items: [NodeGroup: [Node]], restNodeIds: [UUID]) -> [CoinsNodesListState.Section] {
        processedGroups.map {
            map(
                group: $0,
                nodes: items[$0] ?? .init(),
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
                map(node: $0, group: group, isRest: restNodeIds.contains($0.id))
            }
        )
    }
    
    func map(
        node: Node,
        group: NodeGroup,
        isRest: Bool
    ) -> CoinsNodesListState.Section.Row {
        let indicatorString = node.indicatorString(isRest: isRest, isWs: false)
        var indicatorAttrString = AttributedString(stringLiteral: indicatorString)
        indicatorAttrString.foregroundColor = .init(uiColor: node.indicatorColor)
        
        return .init(
            id: node.id,
            group: group,
            isEnabled: node.isEnabled,
            title: node.asString(),
            connectionStatus: indicatorAttrString,
            description: node.statusString(showVersion: true) ?? .empty
        )
    }
}
