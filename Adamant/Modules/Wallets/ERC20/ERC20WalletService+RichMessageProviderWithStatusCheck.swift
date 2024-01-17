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
import CommonKit

extension ERC20WalletService {
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
        
        let erc20Transaction: EthTransaction
        
        do {
            erc20Transaction = try await getTransaction(by: hash)
        } catch {
            return .init(error: error)
        }
        
        return await .init(
            sentDate: erc20Transaction.date,
            status: getStatus(
                erc20Transaction: erc20Transaction,
                transaction: transaction
            )
        )
    }
}

private extension ERC20WalletService {
    func getStatus(
        erc20Transaction: EthTransaction,
        transaction: CoinTransaction
    ) async -> TransactionStatus {
        let status = erc20Transaction.receiptStatus.asTransactionStatus()
        guard status == .success else { return status }
        
        // MARK: Check addresses
        
        guard let realSenderAddress = try? await getWalletAddress(byAdamantAddress: transaction.senderAddress)
        else {
            return .inconsistent(.senderCryptoAddressUnavailable(tokenSymbol))
        }
        
        guard let realRecipientAddress = try? await getWalletAddress(byAdamantAddress: transaction.recipientAddress)
        else {
            return .inconsistent(.recipientCryptoAddressUnavailable(tokenSymbol))
        }
        
        if transaction.isOutgoing {
            guard realSenderAddress == erc20Transaction.senderAddress,
                  erc20Transaction.senderAddress == ethWallet?.address
            else {
                return .inconsistent(.senderCryptoAddressMismatch(tokenSymbol))
            }
        } else {
            guard realRecipientAddress == erc20Transaction.recipientAddress,
                  erc20Transaction.recipientAddress == ethWallet?.address
            else {
                return .inconsistent(.recipientCryptoAddressMismatch(tokenSymbol))
            }
        }
        
        // MARK: Compare amounts
        guard let reportedValue = reportedValue(for: transaction) else {
            return .inconsistent(.wrongAmount)
        }
        
        let min = reportedValue - reportedValue*0.005
        let max = reportedValue + reportedValue*0.005
        
        guard (min...max).contains(erc20Transaction.value ?? 0) else {
            return .inconsistent(.wrongAmount)
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
