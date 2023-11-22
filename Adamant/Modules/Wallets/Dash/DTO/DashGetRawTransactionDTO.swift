//
//  DashGetRawTransactionDTO.swift
//  Adamant
//
//  Created by Andrew G on 17.11.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation

struct DashGetRawTransactionDTO: Encodable {
    let method: String
    let params: [Parameter]
    
    init(hash: String) {
        self.method = "getrawtransaction"
        self.params = [.string(hash), .bool(true)]
    }
}

extension DashGetRawTransactionDTO {
    enum Parameter {
        case string(String)
        case bool(Bool)
    }
}

extension DashGetRawTransactionDTO.Parameter: Encodable {
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
