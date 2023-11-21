//
//  DashGetRawTransactionDTO.swift
//  Adamant
//
//  Created by Andrew G on 17.11.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation

struct DashGetRawTransactionDTO: Codable {
    let method: String
    let params: [Parameter]
    
    init(hash: String) {
        self.method = "getrawtransaction"
        self.params = [.hash(hash), .bool(true)]
    }
}

extension DashGetRawTransactionDTO {
    enum Parameter: Codable {
        case hash(String)
        case bool(Bool)
    }
}
