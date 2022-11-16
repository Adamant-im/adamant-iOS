//
//  ERC20WalletService+RichMessageProviderWithStatusCheck.swift
//  Adamant
//
//  Created by Anton Boyarkin on 06/07/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import Foundation
import web3swift
import struct BigInt.BigUInt

extension ERC20WalletService: RichMessageProviderWithStatusCheck {
    func statusFor(transaction: RichMessageTransaction, completion: @escaping (WalletServiceResult<TransactionStatus>) -> Void) {
        guard let hash = transaction.richContent?[RichContentKeys.transfer.hash] else {
            completion(.failure(error: WalletServiceError.internalError(message: "Failed to get transaction hash", error: nil)))
            return
        }
        
        // MARK: Get transaction
        self.getTransaction(by: hash) { result in
            var status: TransactionStatus
            var transactionDate: Date
            
            switch result {
            case .success(result: let tx):
                status = tx.transactionStatus ?? .pending
                
                guard status == .success, let date = transaction.date as Date? else {
                    completion(.success(result: status))
                    return
                }
                
                transactionDate = date
                
                let start = transactionDate.addingTimeInterval(-60 * 5)
                let end = transactionDate.addingTimeInterval(self.consistencyMaxTime)
                let range = start...end
                
                // MARK: Check addresses
                if transaction.isOutgoing {
                    guard let id = self.ethWallet?.address, tx.senderAddress == id else {
                        completion(.success(result: .warning))
                        return
                    }
                } else {
                    guard let id = self.ethWallet?.address, tx.to == id else {
                        completion(.success(result: .warning))
                        return
                    }
                }
                
                // MARK: Check dates
                guard range.contains(transaction.dateValue ?? Date()) else {
                    completion(.success(result: .warning))
                    return
                }
                
                // MARK: Compare amounts
                guard let raw = transaction.richContent?[RichContentKeys.transfer.amount], let reportedValue = AdamantBalanceFormat.deserializeBalance(from: raw) else {
                    completion(.success(result: .warning))
                    return
                }
                
                let min = reportedValue - reportedValue*0.005
                let max = reportedValue + reportedValue*0.005
                
                guard (min...max).contains(tx.value ?? 0) else {
                    completion(.success(result: .warning))
                    return
                }
                
                completion(.success(result: .success))
                
            case .failure(error: let error):
                guard case let .remoteServiceError(message) = error,
                      message == "Invalid value from Ethereum node"
                else {
                    completion(.failure(error: error))
                    return
                }
                completion(.success(result: .pending))
            }
        }
    }
}
