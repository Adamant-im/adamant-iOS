//
//  Nodes+Allowance.swift
//  Adamant
//
//  Created by Andrey on 05.09.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

public extension Collection where Element == Node {
    func getAllowedNodes(sortedBySpeedDescending: Bool, needWS: Bool) -> [Node] {
        var allowedNodes = filter {
            $0.connectionStatus == .allowed
                && (!needWS || $0.wsEnabled)
        }
        
        if allowedNodes.isEmpty && !needWS {
            allowedNodes = filter { $0.isEnabled }
        }
        
        return sortedBySpeedDescending
            ? allowedNodes.sorted {
                $0.ping ?? .greatestFiniteMagnitude < $1.ping ?? .greatestFiniteMagnitude
            }
            : allowedNodes.shuffled()
    }
}
