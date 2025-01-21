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
    func map(
        group: NodeGroup,
        nodesInfo: NodesListInfo
    ) -> CoinsNodesListState.Section {
        .init(
            id: group,
            title: group.name,
            rows: nodesInfo.nodes.map { node in
                map(
                    node: node,
                    group: group,
                    isRest: nodesInfo.chosenNodeId.map { $0 == node.id } ?? false
                )
            }
        )
    }
}

private extension CoinsNodesListMapper {
    func map(
        node: Node,
        group: NodeGroup,
        isRest: Bool
    ) -> CoinsNodesListState.Section.Row {
        let indicatorString = node.indicatorString(isRest: isRest, isWs: false)
        var indicatorAttrString = AttributedString(stringLiteral: indicatorString)
        indicatorAttrString.foregroundColor = .init(uiColor: node.indicatorColor)
        
        var titleAttrString = AttributedString(stringLiteral: node.title)
        titleAttrString.foregroundColor = .init(uiColor: node.titleColor)
        
        let subtitleString = node.statusString(
            showVersion: true,
            heightType: group.heightType
        ) ?? .empty
        
        var subtitleAttrString = AttributedString(stringLiteral: subtitleString)
        subtitleAttrString.foregroundColor = .init(uiColor: node.statusStringColor)
        
        return .init(
            id: node.id,
            group: group,
            isEnabled: node.isEnabled,
            title: titleAttrString,
            connectionStatus: indicatorAttrString,
            subtitle: subtitleAttrString
        )
    }
}
