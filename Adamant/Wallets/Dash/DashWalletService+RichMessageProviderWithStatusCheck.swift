//
//  DashWalletService+RichMessageProviderWithStatusCheck.swift
//  Adamant
//
//  Created by Anton Boyarkin on 26/05/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import Foundation

extension DashWalletService: RichMessageProviderWithStatusCheck {
    func statusFor(transaction: RichMessageTransaction) async throws -> TransactionStatus {
        guard let hash = transaction.richContent?[RichContentKeys.transfer.hash], let date = transaction.date as Date? else {
            throw WalletServiceError.internalError(message: "Failed to get transaction hash", error: nil)
        }
        
        guard let walletAddress = dashWallet?.address else {
            throw WalletServiceError.notLogged
        }
        
        do {
            let dashTransaction = try await getTransaction(by: hash)
            
            // MARK: Check confirmations
            
            guard let confirmations = dashTransaction.confirmations, let dashDate = dashTransaction.date, (confirmations > 0 || dashDate.timeIntervalSinceNow > -60 * 15) else {
                return .registered
            }
            
            // MARK: Check date
            guard let sentDate = dashTransaction.date else {
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
            
            // MARK: Check amount & address
            guard let raw = transaction.richContent?[RichContentKeys.transfer.amount], let reportedValue = AdamantBalanceFormat.deserializeBalance(from: raw) else {
                return .warning
            }
            
            let min = reportedValue - reportedValue*0.005
            let max = reportedValue + reportedValue*0.005
            
            var result: TransactionStatus = .warning
            if transaction.isOutgoing {
                var totalIncome: Decimal = 0
                for output in dashTransaction.outputs {
                    guard !output.addresses.contains(walletAddress) else {
                        continue
                    }
                    
                    totalIncome += output.value
                }
                
                if (min...max).contains(totalIncome) {
                    result = .success
                }
            } else {
                var totalOutcome: Decimal = 0
                for output in dashTransaction.outputs {
                    guard output.addresses.contains(walletAddress) else {
                        continue
                    }
                    
                    totalOutcome += output.value
                }
                
                if (min...max).contains(totalOutcome) {
                    result = .success
                }
            }
            
            guard result == .success else { return result }
            
            // MARK: Check date
            let start = date.addingTimeInterval(-60 * 5)
            let end = date.addingTimeInterval(self.consistencyMaxTime)
            let dateRange = start...end
            
            return dateRange.contains(sentDate)
                ? result
                : .inconsistent
        } catch let error as ApiServiceError {
            if case let .internalError(message, _) = error,
               message == "No transaction" {
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
