//
//  HashableAction.swift
//  
//
//  Created by Andrey Golubenko on 06.12.2022.
//

import Foundation

public struct HashableAction {
    public let id: Int
    public let action: () -> Void
    
    public init(id: Int, action: @escaping () -> Void) {
        self.id = id
        self.action = action
    }
}

extension HashableAction: Equatable {
    public static func == (lhs: HashableAction, rhs: HashableAction) -> Bool {
        lhs.id == rhs.id
    }
}

extension HashableAction: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
