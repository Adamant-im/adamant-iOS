//
//  HashableAction.swift
//  
//
//  Created by Andrey Golubenko on 06.12.2022.
//

import Foundation

public struct HashableAction {
    public let id: String
    public let action: () -> Void
    
    public static let `default` = Self(id: .empty, action: {})
    
    public init(id: String, action: @escaping () -> Void) {
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
