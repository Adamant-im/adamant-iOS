//
//  NodesMergingServiceProtocol.swift
//  Adamant
//
//  Created by Andrew G on 02.08.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

public protocol NodesMergingServiceProtocol {
    func merge(
        savedNodes: [NodeGroup: [Node]],
        defaultNodes: [NodeGroup: [Node]]
    ) -> [NodeGroup: [Node]]
}
