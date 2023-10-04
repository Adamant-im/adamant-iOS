//
//  HashableIDWrapper.swift
//  
//
//  Created by Andrew G on 12.10.2023.
//

struct HashableIDWrapper<Value>: Hashable {
    let identifier: ComplexIdentifier
    let value: Value

    func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.identifier == rhs.identifier
    }
}

struct ComplexIdentifier: Hashable {
    let identifier: String
    let index: Int
}
