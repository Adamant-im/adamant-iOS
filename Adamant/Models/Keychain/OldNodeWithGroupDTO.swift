//
//  OldNodeWithGroupDTO.swift
//  Adamant
//
//  Created by Andrew G on 30.07.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import CommonKit

// TODO: Remove after a few updates (it's used for migration)
struct OldNodeWithGroupDTO: Codable {
    let group: NodeGroup
    let node: OldNodeDTO
}

extension OldNodeWithGroupDTO {
    func mapToModernDto() -> NodeWithGroupDTO {
        .init(group: group, node: node.mapToModernDto())
    }
}
