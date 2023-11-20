//
//  NodeWithGroup.swift
//  Adamant
//
//  Created by Andrew G on 20.11.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import CommonKit

struct NodeWithGroup: Codable, Equatable {
    let group: NodeGroup
    var node: Node
}
