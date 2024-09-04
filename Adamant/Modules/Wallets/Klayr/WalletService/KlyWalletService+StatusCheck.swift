//
//  KlyWalletService+StatusCheck.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 08.07.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import LiskKit
import CommonKit

extension KlyWalletService {
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
        
        var klyTransaction: Transactions.TransactionModel
        
        do {
            klyTransaction = try await getTransaction(by: hash)
        } catch {
            return .init(error: error)
        }
        
        klyTransaction.updateConfirmations(value: lastHeight)
        
        return await .init(
            sentDate: klyTransaction.sentDate,
            status: getStatus(
                klyTransaction: klyTransaction,
                transaction: transaction
            )
        )
    }
}

private extension KlyWalletService {
    func getStatus(
        klyTransaction: Transactions.TransactionModel,
        transaction: CoinTransaction
    ) async -> TransactionStatus {
        guard klyTransaction.blockId != nil else { return .registered }
        
        guard klyTransaction.executionStatus != .failed else {
            return .failed
        }
        
        guard let status = klyTransaction.transactionStatus else {
            return .inconsistent(.unknown)
        }
        
        guard status == .success else {
            return status
        }
        
        // MARK: Check address
        
        var realSenderAddress = klyTransaction.senderAddress
        var realRecipientAddress = klyTransaction.recipientAddress
        
        if transaction is RichMessageTransaction {
            guard let senderAddress = try? await getWalletAddress(byAdamantAddress: transaction.senderAddress)
            else {
                return .inconsistent(.senderCryptoAddressUnavailable(tokenSymbol))
            }
            
            guard let recipientAddress = try? await getWalletAddress(byAdamantAddress: transaction.recipientAddress)
            else {
                return .inconsistent(.recipientCryptoAddressUnavailable(tokenSymbol))
            }
            
            realSenderAddress = senderAddress
            realRecipientAddress = recipientAddress
        }
        
        guard klyTransaction.senderAddress.caseInsensitiveCompare(realSenderAddress) == .orderedSame else {
            return .inconsistent(.senderCryptoAddressMismatch(tokenSymbol))
        }
        
        guard klyTransaction.recipientAddress.caseInsensitiveCompare(realRecipientAddress) == .orderedSame else {
            return .inconsistent(.recipientCryptoAddressMismatch(tokenSymbol))
        }
        
        if transaction.isOutgoing {
            guard klyWallet?.address.caseInsensitiveCompare(klyTransaction.senderAddress) == .orderedSame else {
                return .inconsistent(.senderCryptoAddressMismatch(tokenSymbol))
            }
        } else {
            guard klyWallet?.address.caseInsensitiveCompare(klyTransaction.recipientAddress) == .orderedSame else {
                return .inconsistent(.recipientCryptoAddressMismatch(tokenSymbol))
            }
        }
        
        // MARK: Check amount
        guard isAmountCorrect(
            transaction: transaction,
            klyTransaction: klyTransaction
        ) else { return .inconsistent(.wrongAmount) }
        
        return .success
    }
    
    func isAmountCorrect(
        transaction: CoinTransaction,
        klyTransaction: Transactions.TransactionModel
    ) -> Bool {
        if let transaction = transaction as? RichMessageTransaction,
           let raw = transaction.getRichValue(for: RichContentKeys.transfer.amount),
           let reported = AdamantBalanceFormat.deserializeBalance(from: raw) {
            let min = reported - reported*0.005
            let max = reported + reported*0.005
            
            let amount = klyTransaction.amountValue ?? 0
            return amount <= max && amount >= min
        }
        
        return transaction.amountValue == klyTransaction.amountValue
    }
}
