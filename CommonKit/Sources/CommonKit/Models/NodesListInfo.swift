//
//  NodesListInfo.swift
//  CommonKit
//
//  Created by Andrew G on 24.10.2024.
//

import Foundation

public struct NodesListInfo: Equatable, Sendable {
    public let nodes: [Node]
    public let chosenNodeId: UUID?
    
    static let `default` = Self(nodes: .init(), chosenNodeId: .none)
}
