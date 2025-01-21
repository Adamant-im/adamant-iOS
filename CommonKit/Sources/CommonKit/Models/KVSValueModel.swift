//
//  KVSValueModel.swift
//  CommonKit
//
//  Created by Andrew G on 15.01.2025.
//

public struct KVSValueModel: Sendable {
    public let key: String
    public let value: String
    public let keypair: Keypair
    
    public init(
        key: String,
        value: String,
        keypair: Keypair
    ) {
        self.key = key
        self.value = value
        self.keypair = keypair
    }
}
