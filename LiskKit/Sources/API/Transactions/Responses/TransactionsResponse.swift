//
//  TransactionResponse.swift
//  Lisk
//
//  Created by Andrew Barba on 1/2/18.
//

import Foundation

extension Transactions {

    public struct TransactionsResponse: APIResponse {

        public let data: [TransactionModel]
    }
}
