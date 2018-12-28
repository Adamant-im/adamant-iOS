//
//  LskWalletService+RichMessageProviderWithStatusCheck.swift
//  Adamant
//
//  Created by Anton Boyarkin on 06/12/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

extension LskWalletService: RichMessageProviderWithStatusCheck {
    func statusForTransactionBy(hash: String, date: Date?, amount: Double, isOutgoing: Bool, completion: @escaping (WalletServiceResult<TransactionStatus>) -> Void) {
        getTransaction(by: hash) { result in
            switch result {
            case .success(let transaction):
                if var status = transaction.transactionStatus {
                    
                    if status == .success, isOutgoing == false, let date = date {
                        let start = date.addingTimeInterval(-60 * 5)
                        let end = date.addingTimeInterval(60 * 5)
                        let range = start...end
                        if transaction.recipientAddress != self.lskWallet?.address ||
                            !range.contains(transaction.sentDate) ||
                            amount != transaction.amountValue.doubleValue
                            {
                            status = .warning
                        }
                    }
                    
                    completion(.success(result: status))
                } else {
                    completion(.failure(error: WalletServiceError.internalError(message: "Failed to get transaction", error: nil)))
                }
                
            case .failure(let error):
                if case let .internalError(message, _) = error, message == "No transaction" {
                    if let date = date {
                        let timeAgo = -1 * date.timeIntervalSinceNow
                        
                        if timeAgo > 60 * 60 * 3 { // 3h waiting for panding status
                            completion(.success(result: .failed))
                            return
                        }
                    }
                    completion(.success(result: .pending)) // Note: No info about processing transactions
                } else {
                    completion(.failure(error: error.asWalletServiceError()))
                }
            }
        }
    }
}
