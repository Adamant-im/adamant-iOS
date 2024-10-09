//
//  UnsafeSendable.swift
//  CommonKit
//
//  Created by Andrew G on 07.10.2024.
//

public struct UnsafeSendable<T>: @unchecked Sendable {
    public let value: T
    
    public init(_ value: T) {
        self.value = value
    }
}
