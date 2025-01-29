//
//  EthResponseBody.swift
//  Adamant
//
//  Created by Christian Benua on 16.01.2025.
//  Copyright © 2025 Adamant. All rights reserved.
//

struct EthAPIResponse<Result: Codable>: Codable {
    var id: Int = 1
    var jsonrpc = "2.0"
    var result: Result
    
    init(id: Int = 1, jsonrpc: String = "2.0", result: Result) {
        self.id = id
        self.jsonrpc = jsonrpc
        self.result = result
    }
}
