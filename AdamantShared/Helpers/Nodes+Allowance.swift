//
//  Nodes+Allowance.swift
//  Adamant
//
//  Created by Andrey on 05.09.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

extension Collection where Element: Node {
    func getAllowedNodes(sortedBySpeedDescending: Bool, needWS: Bool) -> [Node] {
        var allowedNodes = filter {
            $0.connectionStatus == .allowed
                && (!needWS || $0.status?.wsEnabled ?? false)
        }
        
        if allowedNodes.isEmpty && !needWS {
            allowedNodes = filter { $0.isEnabled }
        }
        
        return sortedBySpeedDescending
            ? allowedNodes.sorted {
                $0.status?.ping ?? .greatestFiniteMagnitude < $1.status?.ping ?? .greatestFiniteMagnitude
            }
            : allowedNodes.shuffled()
    }
}
