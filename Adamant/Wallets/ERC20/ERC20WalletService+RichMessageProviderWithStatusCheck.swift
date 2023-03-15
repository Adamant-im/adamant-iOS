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
        
        do {
            let tx = try await getTransaction(by: hash)
            status = tx.receiptStatus.asTransactionStatus()
            
            guard status == .success,
                  let date = transaction.date as Date?
            else {
                return status
            }
            
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
            
            // MARK: Compare amounts
            guard let raw = transaction.richContent?[RichContentKeys.transfer.amount],
                    let reportedValue = AdamantBalanceFormat.deserializeBalance(from: raw)
            else {
                return .warning
            }
            
            let min = reportedValue - reportedValue*0.005
            let max = reportedValue + reportedValue*0.005
            
            guard
                (min...max).contains(tx.value ?? 0),
                let sentDate = tx.dateValue
            else {
                return .warning
            }
            
            // MARK: Check date
            let start = date.addingTimeInterval(-60 * 5)
            let end = date.addingTimeInterval(self.consistencyMaxTime)
            let dateRange = start...end
            
            return dateRange.contains(sentDate)
                ? .success
                : .inconsistent
        } catch _ as WalletServiceError {
            return .pending
        } catch {
            return .warning
        }
    }
}
