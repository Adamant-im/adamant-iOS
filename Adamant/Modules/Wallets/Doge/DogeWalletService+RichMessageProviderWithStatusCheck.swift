//
//  DogeWalletService+RichMessageProviderWithStatusCheck.swift
//  Adamant
//
//  Created by Anton Boyarkin on 13/03/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import Foundation
import CommonKit

extension DogeWalletService {
    func statusInfoFor(transaction: CoinTransaction) async -> TransactionStatusInfo {
        let hash: String?
        
        if let transaction = transaction as? RichMessageTransaction {
            hash = transaction.getRichValue(for: RichContentKeys.transfer.hash)
        } else {
            hash = transaction.txId
        }
        
        guard let hash = hash else {
            return .init(sentDate: nil, status: .inconsistent)
        }
        
        let dogeTransaction: BTCRawTransaction
        
        do {
            dogeTransaction = try await getTransaction(by: hash)
        } catch {
            return .init(error: error)
        }
        
        return .init(
            sentDate: dogeTransaction.date,
            status: getStatus(
                dogeTransaction: dogeTransaction,
                transaction: transaction
            )
        )
    }
}

private extension DogeWalletService {
    func getStatus(
        dogeTransaction: BTCRawTransaction,
        transaction: CoinTransaction
    ) -> TransactionStatus {
        // MARK: Check confirmations
        guard let confirmations = dogeTransaction.confirmations,
              let dogeDate = dogeTransaction.date,
              (confirmations > 0 || dogeDate.timeIntervalSinceNow > -60 * 15)
        else {
            return .pending
        }
        
        // MARK: Check amount & address
        guard let reportedValue = reportedValue(for: transaction) else {
            return .inconsistent
        }
        
        let min = reportedValue - reportedValue*0.005
        let max = reportedValue + reportedValue*0.005
        
        guard let walletAddress = dogeWallet?.address else {
            return .inconsistent
        }
        
        var result: TransactionStatus = .inconsistent
        if transaction.isOutgoing {
            var totalIncome: Decimal = 0
            for output in dogeTransaction.outputs {
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
        
        return result
    }
    
    func reportedValue(for transaction: CoinTransaction) -> Decimal? {
        guard let transaction = transaction as? RichMessageTransaction
        else {
            return transaction.amountValue
        }
        
        guard
            let raw = transaction.getRichValue(for: RichContentKeys.transfer.amount),
            let reportedValue = AdamantBalanceFormat.deserializeBalance(from: raw)
        else {
            return nil
        }
        
        return reportedValue
    }
}
