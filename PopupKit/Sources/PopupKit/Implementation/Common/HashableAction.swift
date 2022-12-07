//
//  HashableAction.swift
//  
//
//  Created by Andrey Golubenko on 06.12.2022.
//

import Foundation

struct HashableAction {
    let action: () -> Void
}

extension HashableAction: Equatable {
    static func == (lhs: HashableAction, rhs: HashableAction) -> Bool {
        true
    }
}

extension HashableAction: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(String(describing: Self.self))
    }
}
