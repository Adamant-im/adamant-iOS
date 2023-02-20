//
//  LskWalletService+RichMessageProviderWithStatusCheck.swift
//  Adamant
//
//  Created by Anton Boyarkin on 06/12/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

extension LskWalletService: RichMessageProviderWithStatusCheck {
    func statusFor(transaction: RichMessageTransaction) async throws -> TransactionStatus {
        guard let hash = transaction.richContent?[RichContentKeys.transfer.hash],
              let date = transaction.date as Date?
        else {
            throw WalletServiceError.internalError(message: "Failed to get transaction hash", error: nil)
        }
        
        do {
            var lskTransaction = try await getTransaction(by: hash)
            lskTransaction.updateConfirmations(value: self.lastHeight)
            
            guard let status = lskTransaction.transactionStatus else {
                throw WalletServiceError.internalError(message: "Failed to get transaction", error: nil)
            }
            
            guard status == .success else {
                return status
            }
            
            // MARK: Check address
            if transaction.isOutgoing {
                guard lskTransaction.senderAddress == self.lskWallet?.address else {
                    return .warning
                }
            } else {
                guard lskTransaction.recipientAddress == self.lskWallet?.address else {
                    return .warning
                }
            }
            
            // MARK: Check date
            let start = date.addingTimeInterval(-60 * 5)
            let end = date.addingTimeInterval(self.consistencyMaxTime)
            let range = start...end
            
            guard range.contains(lskTransaction.sentDate) else {
                return .warning
            }
            
            // MARK: Check amount
            if let raw = transaction.richContent?[RichContentKeys.transfer.amount], let reported = AdamantBalanceFormat.deserializeBalance(from: raw) {
                let min = reported - reported*0.005
                let max = reported + reported*0.005
                
                guard (min...max).contains(lskTransaction.amountValue ?? 0) else {
                    return .warning
                }
            }
            
            return .success
        } catch let error as ApiServiceError {
            if error.message.contains("does not exist") {
                let timeAgo = -1 * date.timeIntervalSinceNow
                
                let result: TransactionStatus
                if timeAgo > self.consistencyMaxTime {
                    // max time waiting for pending status
                    result = .failed
                } else {
                    // Note: No info about processing transactions
                    result = .pending
                }
                return result
                
            }
            
            throw error.asWalletServiceError()
        } catch {
            throw WalletServiceError.internalError(
                message: String.adamantLocalized.sharedErrors.unknownError,
                error: nil
            )
        }
    }
}
