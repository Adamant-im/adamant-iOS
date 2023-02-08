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
    func statusFor(transaction: RichMessageTransaction) async throws -> TransactionStatus {
        guard let hash = transaction.richContent?[RichContentKeys.transfer.hash] else {
            throw WalletServiceError.internalError(message: "Failed to get transaction hash", error: nil)
        }
        
        // MARK: Get transaction
        var status: TransactionStatus
        var transactionDate: Date
        
        do {
            let tx = try await getTransaction(by: hash)
            status = tx.transactionStatus ?? .pending
            
            guard status == .success,
                  let date = transaction.date as Date?
            else {
                return status
            }
            
            transactionDate = date
            
            let start = transactionDate.addingTimeInterval(-60 * 5)
            let end = transactionDate.addingTimeInterval(self.consistencyMaxTime)
            let range = start...end
            
            // MARK: Check addresses
            if transaction.isOutgoing {
                guard let id = self.ethWallet?.address,
                      tx.senderAddress == id
                else {
                    return .warning
                }
            } else {
                guard let id = self.ethWallet?.address,
                      tx.to == id
                else {
                    return .warning
                }
            }
            
            // MARK: Check dates
            guard range.contains(transaction.dateValue ?? Date()) else {
                return .warning
            }
            
            // MARK: Compare amounts
            guard let raw = transaction.richContent?[RichContentKeys.transfer.amount],
                    let reportedValue = AdamantBalanceFormat.deserializeBalance(from: raw)
            else {
                return .warning
            }
            
            let min = reportedValue - reportedValue*0.005
            let max = reportedValue + reportedValue*0.005
            
            guard (min...max).contains(tx.value ?? 0) else {
                return .warning
            }
            
            return .success
        } catch let error as WalletServiceError {
            guard transaction.transactionStatus == .notInitiated else {
                throw error
            }
            
            return .pending
        } catch {
            throw WalletServiceError.internalError(message: "Failed to get transaction", error: error)
        }
    }
}
