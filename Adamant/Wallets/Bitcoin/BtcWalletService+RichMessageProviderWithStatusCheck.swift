//
//  BtcWalletService+RichMessageProviderWithStatusCheck.swift
//  Adamant
//
//  Created by Anton Boyarkin on 20/02/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import Foundation

extension BtcWalletService: RichMessageProviderWithStatusCheck {
    func statusFor(transaction: RichMessageTransaction) async throws -> TransactionStatus {
        guard let hash = transaction.richContent?[RichContentKeys.transfer.hash], let date = transaction.date as Date? else {
            throw WalletServiceError.internalError(message: "Failed to get transaction hash", error: nil)
        }
        
        do {
            let btcTransaction = try await getTransaction(by: hash)
            guard let status = btcTransaction.transactionStatus else {
                throw WalletServiceError.internalError(message: "Failed to get transaction", error: nil)
            }
            
            guard status == .success else {
                return status
            }
            
            // MARK: Check address
            if transaction.isOutgoing {
                guard btcTransaction.senderAddress == self.btcWallet?.address else {
                    return .warning
                }
            } else {
                guard btcTransaction.recipientAddress == self.btcWallet?.address else {
                    return .warning
                }
            }
            
            // MARK: Check date
            let start = date.addingTimeInterval(-60 * 5)
            let end = date.addingTimeInterval(self.consistencyMaxTime)
            let range = start...end
            
            guard let sentDate = btcTransaction.dateValue else {
                return .warning
            }
            
            guard range.contains(sentDate) else {
                return .warning
            }
            
            // MARK: Check amount
            if let raw = transaction.richContent?[RichContentKeys.transfer.amount], let reported = AdamantBalanceFormat.deserializeBalance(from: raw) {
                guard reported == btcTransaction.amountValue else {
                    return .warning
                }
            }
            
            return .success
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
                return result
                
            }
            
            throw error
        } catch {
            throw WalletServiceError.internalError(
                message: String.adamantLocalized.sharedErrors.unknownError,
                error: nil
            )
        }
    }
}
