//
//  LskWalletService+RichMessageProviderWithStatusCheck.swift
//  Adamant
//
//  Created by Anton Boyarkin on 06/12/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

extension LskWalletService: RichMessageProviderWithStatusCheck {
    func statusFor(transaction: RichMessageTransaction, completion: @escaping (WalletServiceResult<TransactionStatus>) -> Void) {
        guard let hash = transaction.richContent?[RichContentKeys.transfer.hash], let date = transaction.date as Date? else {
            completion(.failure(error: WalletServiceError.internalError(message: "Failed to get transaction hash", error: nil)))
            return
        }
        
        getTransaction(by: hash) { result in
            switch result {
            case .success(let lskTransaction):
                // MARK: Check status
                guard let status = lskTransaction.transactionStatus else {
                    completion(.failure(error: WalletServiceError.internalError(message: "Failed to get transaction", error: nil)))
                    return
                }
                
                guard status == .success else {
                    completion(.success(result: status))
                    return
                }
                
                // MARK: Check address
                if transaction.isOutgoing {
                    guard lskTransaction.senderAddress == self.lskWallet?.address else {
                        completion(.success(result: .warning))
                        return
                    }
                } else {
                    guard lskTransaction.recipientAddress == self.lskWallet?.address else {
                        completion(.success(result: .warning))
                        return
                    }
                }
                
                // MARK: Check date
                let start = date.addingTimeInterval(-60 * 5)
                let end = date.addingTimeInterval(60 * 5)
                let range = start...end
                
                guard range.contains(lskTransaction.sentDate) else {
                    completion(.success(result: .warning))
                    return
                }
                    
                // MARK: Check amount
                if let raw = transaction.richContent?[RichContentKeys.transfer.amount], let reported = AdamantBalanceFormat.deserializeBalance(from: raw) {
                    let min = reported - reported*0.005
                    let max = reported + reported*0.005
                    
                    guard (min...max).contains(lskTransaction.amountValue) else {
                        completion(.success(result: .warning))
                        return
                    }
                }
                
                completion(.success(result: .success))
                
            case .failure(let error):
                if case let .internalError(message, _) = error, message == "No transaction" {
                    let timeAgo = -1 * date.timeIntervalSinceNow
                    
                    let result: TransactionStatus
                    if timeAgo > 60 * 60 * 3 {
                        // 3h waiting for pending status
                        result = .failed
                    } else {
                        // Note: No info about processing transactions
                        result = .pending
                    }
                    completion(.success(result: result))
                    
                } else {
                    completion(.failure(error: error.asWalletServiceError()))
                }
            }
        }
    }
}
