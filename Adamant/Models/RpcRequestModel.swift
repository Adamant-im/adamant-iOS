//
//  RpcRequestModel.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 31.01.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import Foundation

struct RpcRequest: Encodable {
    let method: String
    let id: String
    let params: [Parameter]
    let jsonrpc: String = "2.0"
    
    init(method: String, id: String, params: [Parameter]) {
        self.method = method
        self.id = id
        self.params = params
    }
    
    init(method: String, params: [Parameter]) {
        self.method = method
        self.id = method
        self.params = params
    }
    
    init(method: String) {
        self.method = method
        self.id = method
        self.params = []
    }
}

extension RpcRequest {
    enum Parameter {
        case string(String)
        case bool(Bool)
    }
}

extension RpcRequest.Parameter: Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch self {
        case let .string(value):
            try container.encode(value)
        case let .bool(value):
            try container.encode(value)
        }
    }
}
