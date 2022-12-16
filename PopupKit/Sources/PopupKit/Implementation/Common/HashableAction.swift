//
//  HashableAction.swift
//  
//
//  Created by Andrey Golubenko on 06.12.2022.
//

import Foundation

struct HashableAction {
    let id: Int
    let action: () -> Void
}

extension HashableAction: Equatable {
    static func == (lhs: HashableAction, rhs: HashableAction) -> Bool {
        lhs.id == rhs.id
    }
}

extension HashableAction: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
