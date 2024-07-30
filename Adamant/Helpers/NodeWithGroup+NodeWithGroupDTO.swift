//
//  NodeWithGroup+NodeWithGroupDTO.swift
//  Adamant
//
//  Created by Andrew G on 28.07.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

extension NodeWithGroup {
    func mapToDto() -> NodeWithGroupDTO {
        .init(group: group, node: node.mapToDto())
    }
}

extension NodeWithGroupDTO {
    func mapToModel() -> NodeWithGroup {
        .init(group: group, node: node.mapToModel())
    }
}
