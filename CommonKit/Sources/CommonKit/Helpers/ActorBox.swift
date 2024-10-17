//
//  ActorBox.swift
//  CommonKit
//
//  Created by Andrew G on 17.10.2024.
//

public actor ActorBox<Value> {
    public var value: Value
    
    public init(_ value: Value) {
        self.value = value
    }
}
