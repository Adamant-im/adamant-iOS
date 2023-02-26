//
//  ComparableAction.swift
//  Adamant
//
//  Created by Andrey Golubenko on 16.01.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

struct ComparableAction: Equatable {
    let id: String
    let action: () -> Void
    
    init(id: String = "", action: @escaping () -> Void) {
        self.id = id
        self.action = action
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}
