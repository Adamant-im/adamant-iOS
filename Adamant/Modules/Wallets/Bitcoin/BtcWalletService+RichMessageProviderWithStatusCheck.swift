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
            
            return await .init(
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
    ) async -> TransactionStatus {
        guard let status = btcTransaction.transactionStatus else {
            return .inconsistent(.unknown)
        }
        
        guard status == .success else {
            return status
        }
        
        // MARK: Check address
        
        guard let realSenderAddress = try? await getWalletAddress(byAdamantAddress: transaction.senderAddress)
        else {
            return .inconsistent(.senderCryptoAddressUnavailable(tokenSymbol))
        }
        
        guard let realRecipientAddress = try? await getWalletAddress(byAdamantAddress: transaction.recipientAddress)
        else {
            return .inconsistent(.recipientCryptoAddressUnavailable(tokenSymbol))
        }
        
        if transaction.isOutgoing {
             guard realSenderAddress == btcTransaction.senderAddress,
                   btcTransaction.senderAddress == btcWallet?.address
             else {
                 return .inconsistent(.senderCryptoAddressMismatch(tokenSymbol))
             }
         } else {
             guard realRecipientAddress == btcTransaction.recipientAddress,
                   btcTransaction.recipientAddress == btcWallet?.address
             else {
                 return .inconsistent(.recipientCryptoAddressMismatch(tokenSymbol))
             }
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
