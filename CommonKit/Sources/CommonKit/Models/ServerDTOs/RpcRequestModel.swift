//
//  RpcRequestModel.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 31.01.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import Foundation

public struct RpcRequest: Encodable, Sendable {
    public let method: String
    public let id: String
    public let params: [Parameter]
    public let jsonrpc: String = "2.0"
    
    public init(method: String, id: String, params: [Parameter]) {
        self.method = method
        self.id = id
        self.params = params
    }
    
    public init(method: String, params: [Parameter]) {
        self.method = method
        self.id = method
        self.params = params
    }
    
    public init(method: String) {
        self.method = method
        self.id = method
        self.params = []
    }
}

public extension RpcRequest {
    enum Parameter: Sendable {
        case string(String)
        case bool(Bool)
    }
}

extension RpcRequest.Parameter: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch self {
        case let .string(value):
            try container.encode(value)
        case let .bool(value):
            try container.encode(value)
        }
    }
}
