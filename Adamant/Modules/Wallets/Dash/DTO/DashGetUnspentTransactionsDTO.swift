//
//  DashGetUnspentTransactionsDTO.swift
//  Adamant
//
//  Created by Andrew G on 17.11.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation

struct DashGetUnspentTransactionDTO: Codable {
    let method: String
    let params: [String]
    
    init(address: String) {
        self.method = "getaddressutxos"
        self.params = [address]
    }
}
