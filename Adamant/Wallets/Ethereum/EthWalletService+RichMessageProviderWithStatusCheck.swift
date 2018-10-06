//
//  EthWalletService+RichMessageProviderWithStatusCheck.swift
//  Adamant
//
//  Created by Anokhov Pavel on 06.10.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import web3swift

extension EthWalletService: RichMessageProviderWithStatusCheck {
    func statusForTransactionBy(hash: String, completion: @escaping (WalletServiceResult<TransactionStatus>) -> Void) {
        switch web3.eth.getTransactionReceipt(hash) {
        case .success(let receipt):
            completion(.success(result: receipt.status.asTransactionStatus()))
            
        case .failure(let error):
            completion(.failure(error: error.asWalletServiceError()))
        }
    }
}

extension TransactionReceipt.TXStatus {
    func asTransactionStatus() -> TransactionStatus {
        switch self {
        case .ok:
            return .success
            
        case .failed:
            return .failed
            
        case .notYetProcessed:
            return .pending
        }
    }
}
