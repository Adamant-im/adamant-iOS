//
//  LskWalletService+RichMessageProviderWithStatusCheck.swift
//  Adamant
//
//  Created by Anton Boyarkin on 06/12/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

extension LskWalletService: RichMessageProviderWithStatusCheck {
    func statusForTransactionBy(hash: String, completion: @escaping (WalletServiceResult<TransactionStatus>) -> Void) {
        getTransaction(by: hash) { result in
            switch result {
            case .success(let traansaction):
                if let status = traansaction.transactionStatus {
                    completion(.success(result: status))
                } else {
                    completion(.failure(error: WalletServiceError.internalError(message: "Failed to get transaction", error: nil)))
                }
                
            case .failure(let error):
                if case let .internalError(message, _) = error, message == "No transaction" {
                    completion(.success(result: .pending)) // Note: No info about processing transactions
                } else {
                    completion(.failure(error: error.asWalletServiceError()))
                }
            }
        }
    }
}
