//
//  Web3Swift+Adamant.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 24.01.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import web3swift
import Web3Core

// MARK: Web3Swift
// Make requests more comfortable

extension IEth {
    func transactionDetails(_ txHash: String) async throws -> Web3Core.TransactionDetails {
        let request = APIRequest.getTransactionByHash(txHash)
        return try await APIRequest.sendRequest(with: provider, for: request).result
    }
    
    func transactionReceipt(_ txHash: String) async throws -> Web3Core.TransactionReceipt {
        let request = APIRequest.getTransactionReceipt(txHash)
        return try await APIRequest.sendRequest(with: provider, for: request).result
    }
}
