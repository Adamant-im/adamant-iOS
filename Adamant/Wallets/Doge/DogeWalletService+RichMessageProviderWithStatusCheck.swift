//
//  DogeWalletService+RichMessageProviderWithStatusCheck.swift
//  Adamant
//
//  Created by Anton Boyarkin on 13/03/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import Foundation

extension DogeWalletService: RichMessageProviderWithStatusCheck {
    func statusFor(transaction: RichMessageTransaction, completion: @escaping (WalletServiceResult<TransactionStatus>) -> Void) {
        guard let hash = transaction.richContent?[RichContentKeys.transfer.hash], let date = transaction.date as Date? else {
            completion(.failure(error: WalletServiceError.internalError(message: "Failed to get transaction hash", error: nil)))
            return
        }
        
        guard let walletAddress = dogeWallet?.address else {
            completion(.failure(error: .notLogged))
            return
        }
        
        getTransaction(by: hash) { result in
            switch result {
            case .success(let dogeTransaction):
                // MARK: Check confirmations
                guard let confirmations = dogeTransaction.confirmations, let dogeDate = dogeTransaction.date, (confirmations > 0 || dogeDate.timeIntervalSinceNow > -60 * 15) else {
                    completion(.success(result: .pending))
                    return
                }
                
                // MARK: Check date
                guard let sentDate = dogeTransaction.date else {
                    let timeAgo = -1 * date.timeIntervalSinceNow
                    
                    let result: TransactionStatus
                    if timeAgo > 60 * 10 {
                        // 10m waiting for pending status
                        result = .failed
                    } else {
                        // Note: No info about processing transactions
                        result = .pending
                    }
                    completion(.success(result: result))
                    return
                }
                
                // 1 day
                let dayInterval = TimeInterval(60 * 60 * 24)
                let start = date.addingTimeInterval(-dayInterval)
                let end = date.addingTimeInterval(dayInterval)
                let range = start...end
                
                guard range.contains(sentDate) else {
                    completion(.success(result: .warning))
                    return
                }
                
                // MARK: Check amount & address
                guard let raw = transaction.richContent?[RichContentKeys.transfer.amount], let reportedValue = AdamantBalanceFormat.deserializeBalance(from: raw) else {
                    completion(.success(result: .warning))
                    return
                }
                
                let min = reportedValue - reportedValue*0.005
                let max = reportedValue + reportedValue*0.005
                
                var result: TransactionStatus = .warning
                if transaction.isOutgoing {
                    var totalIncome: Decimal = 0
                    for input in dogeTransaction.inputs {
                        guard input.sender == walletAddress else {
                            continue
                        }
                        
                        totalIncome += input.value
                    }
                    
                    if (min...max).contains(totalIncome) {
                        result = .success
                    }
                } else {
                    var totalOutcome: Decimal = 0
                    for output in dogeTransaction.outputs {
                        guard output.addresses.contains(walletAddress) else {
                            continue
                        }
                        
                        totalOutcome += output.value
                    }
                    
                    if (min...max).contains(totalOutcome) {
                        result = .success
                    }
                }
                
                completion(.success(result: result))
                
            case .failure(let error):
                if case let .internalError(message, _) = error, message == "No transaction" {
                    let timeAgo = -1 * date.timeIntervalSinceNow
                    
                    let result: TransactionStatus
                    if timeAgo > 60 * 10 {
                        // 10m waiting for pending status
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
