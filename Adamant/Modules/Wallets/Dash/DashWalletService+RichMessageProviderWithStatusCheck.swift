//
//  DashWalletService+RichMessageProviderWithStatusCheck.swift
//  Adamant
//
//  Created by Anton Boyarkin on 26/05/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import Foundation
import CommonKit

extension DashWalletService: RichMessageProviderWithStatusCheck {
    func statusInfoFor(transaction: RichMessageTransaction) async -> TransactionStatusInfo {
        guard let hash = transaction.getRichValue(for: RichContentKeys.transfer.hash)
        else {
            return .init(sentDate: nil, status: .inconsistent)
        }
        
        let dashTransaction: BTCRawTransaction
        
        do {
            dashTransaction = try await getTransaction(by: hash)
        } catch {
            switch error {
            case ApiServiceError.networkError(_):
                return .init(sentDate: nil, status: .noNetwork)
            default:
                return .init(sentDate: nil, status: .pending)
            }
        }
        
        return .init(
            sentDate: dashTransaction.date,
            status: getStatus(dashTransaction: dashTransaction, transaction: transaction)
        )
    }
}

private extension DashWalletService {
    func getStatus(
        dashTransaction: BTCRawTransaction,
        transaction: RichMessageTransaction
    ) -> TransactionStatus {
        // MARK: Check confirmations
        
        guard let confirmations = dashTransaction.confirmations, let dashDate = dashTransaction.date, (confirmations > 0 || dashDate.timeIntervalSinceNow > -60 * 15) else {
            return .registered
        }
        
        // MARK: Check amount & address
        guard let raw = transaction.getRichValue(for: RichContentKeys.transfer.amount),
              let reportedValue = AdamantBalanceFormat.deserializeBalance(from: raw) else {
            return .inconsistent
        }
        
        let min = reportedValue - reportedValue*0.005
        let max = reportedValue + reportedValue*0.005
        
        guard let walletAddress = dashWallet?.address else {
            return .inconsistent
        }
        
        var result: TransactionStatus = .inconsistent
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
        
        return result
    }
}
