//
//  BtcWalletService+RichMessageProviderWithStatusCheck.swift
//  Adamant
//
//  Created by Anton Boyarkin on 20/02/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import Foundation
import CommonKit

extension BtcWalletService {
    func statusInfoFor(transaction: CoinTransaction) async -> TransactionStatusInfo {
        let hash: String?
        
        if let transaction = transaction as? RichMessageTransaction {
            hash = transaction.getRichValue(for: RichContentKeys.transfer.hash)
        } else {
            hash = transaction.txId
        }
        
        guard let hash = hash else {
            return .init(sentDate: nil, status: .inconsistent(.wrongTxHash))
        }
        
        do {
            let btcTransaction = try await getTransaction(by: hash)
            
            return .init(
                sentDate: btcTransaction.dateValue,
                status: getStatus(transaction: transaction, btcTransaction: btcTransaction)
            )
        } catch {
            return .init(error: error)
        }
    }
}

private extension BtcWalletService {
    func getStatus(
        transaction: CoinTransaction,
        btcTransaction: BtcTransaction
    ) -> TransactionStatus {
        guard let status = btcTransaction.transactionStatus else {
            return .inconsistent(.unknown)
        }
        
        guard status == .success else {
            return status
        }
        
        // MARK: Check address
        
        if transaction.isOutgoing && btcTransaction.senderAddress != btcWallet?.address {
            return .inconsistent(.senderCryptoAddressMismatch)
        }
        
        if !transaction.isOutgoing && btcTransaction.recipientAddress != btcWallet?.address {
            return .inconsistent(.recipientCryptoAddressMismatch)
        }
        
        // MARK: Check amount
        if let reported = reportedValue(for: transaction) {
            guard reported == btcTransaction.amountValue else {
                return .inconsistent(.wrongAmount)
            }
        }
        
        return .success
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
