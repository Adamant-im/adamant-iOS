//
//  File.swift
//  
//
//  Created by Stanislav Jelezoglo on 18.12.2023.
//

import Foundation

public struct Balance: Decodable {
    public let tokenID: String
    public let availableBalance: String
}

struct BalancesResponse: Decodable {
    let balances: [Balance]
}

/*
 {
   "balances": [
     {
       "tokenID": "0200000000000000",
       "availableBalance": "1000000000",
       "lockedBalances": []
     }
   ]
 }
 */
