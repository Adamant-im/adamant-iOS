//
//  DashSendRawTransactionDTO.swift
//  Adamant
//
//  Created by Andrew G on 17.11.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation

struct DashSendRawTransactionDTO: Codable {
    let method: String
    let params: [String]
    
    init(txHex: String) {
        self.method = "sendrawtransaction"
        self.params = [txHex]
    }
}
