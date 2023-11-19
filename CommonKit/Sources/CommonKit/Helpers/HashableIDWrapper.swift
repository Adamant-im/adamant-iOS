//
//  File.swift
//  
//
//  Created by Stanislav Jelezoglo on 19.10.2023.
//

import Foundation

public struct HashableIDWrapper<Value>: Hashable {
    public let identifier: ComplexIdentifier
    public let value: Value
    
    public init(identifier: ComplexIdentifier, value: Value) {
        self.identifier = identifier
        self.value = value
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.identifier == rhs.identifier
    }
}

public struct ComplexIdentifier: Hashable {
    public let identifier: String
    public let index: Int
    
    public init(identifier: String, index: Int) {
        self.identifier = identifier
        self.index = index
    }
}
