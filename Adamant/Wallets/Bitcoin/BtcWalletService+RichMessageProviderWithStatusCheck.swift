//
//  BtcWalletService+RichMessageProviderWithStatusCheck.swift
//  Adamant
//
//  Created by Anton Boyarkin on 20/02/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import Foundation

extension BtcWalletService: RichMessageProviderWithStatusCheck {
    func statusFor(transaction: RichMessageTransaction, completion: @escaping (WalletServiceResult<TransactionStatus>) -> Void) {
        guard let hash = transaction.richContent?[RichContentKeys.transfer.hash], let date = transaction.date as Date? else {
            completion(.failure(error: WalletServiceError.internalError(message: "Failed to get transaction hash", error: nil)))
            return
        }
        
        Task {
            do {
                let btcTransaction = try await getTransaction(by: hash)
                guard let status = btcTransaction.transactionStatus else {
                    completion(.failure(error: WalletServiceError.internalError(message: "Failed to get transaction", error: nil)))
                    return
                }
                
                guard status == .success else {
                    completion(.success(result: status))
                    return
                }
                
                // MARK: Check address
                if transaction.isOutgoing {
                    guard btcTransaction.senderAddress == self.btcWallet?.address else {
                        completion(.success(result: .warning))
                        return
                    }
                } else {
                    guard btcTransaction.recipientAddress == self.btcWallet?.address else {
                        completion(.success(result: .warning))
                        return
                    }
                }
                
                // MARK: Check date
                let start = date.addingTimeInterval(-60 * 5)
                let end = date.addingTimeInterval(self.consistencyMaxTime)
                let range = start...end
                
                guard let sentDate = btcTransaction.dateValue else {
                    completion(.success(result: .warning))
                    return
                }
                
                guard range.contains(sentDate) else {
                    completion(.success(result: .warning))
                    return
                }
                
                // MARK: Check amount
                if let raw = transaction.richContent?[RichContentKeys.transfer.amount], let reported = AdamantBalanceFormat.deserializeBalance(from: raw) {
                    guard reported == btcTransaction.amountValue else {
                        completion(.success(result: .warning))
                        return
                    }
                }
                
                completion(.success(result: .success))
            } catch let error as WalletServiceError {
                if case let .internalError(message, _) = error, message == "No transaction" {
                    let timeAgo = -1 * date.timeIntervalSinceNow
                    
                    let result: TransactionStatus
                    if timeAgo > self.consistencyMaxTime {
                        // max time waiting for pending status
                        result = .failed
                    } else {
                        // Note: No info about processing transactions
                        result = .pending
                    }
                    completion(.success(result: result))
                    
                } else {
                    completion(.failure(error: error))
                }
            }
        }
    }
}
