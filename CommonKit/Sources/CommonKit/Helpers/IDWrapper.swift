//
//  IDWrapper.swift
//  Adamant
//
//  Created by Andrey Golubenko on 17.07.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation

public struct IDWrapper<T>: Identifiable {
    public let id: String
    public let value: T
    
    public init(id: String, value: T) {
        self.id = id
        self.value = value
    }
}

extension IDWrapper: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}

extension IDWrapper: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
