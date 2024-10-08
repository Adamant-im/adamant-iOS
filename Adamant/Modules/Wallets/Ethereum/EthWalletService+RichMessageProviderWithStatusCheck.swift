//
//  EthWalletService+RichMessageProviderWithStatusCheck.swift
//  Adamant
//
//  Created by Anokhov Pavel on 06.10.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
@preconcurrency import web3swift
@preconcurrency import Web3Core
import CommonKit

extension EthWalletService {
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
        
        let transactionInfo: EthTransactionInfo
        
        do {
            transactionInfo = try await ethApiService.requestWeb3 { [weak self] web3 in
                guard let self = self else { throw WalletServiceError.internalError(.unknownError) }
                return try await getTransactionInfo(hash: hash, web3: web3)
            }.get()
        } catch {
            return .init(error: error)
        }
        
        guard
            let details = transactionInfo.details,
            let receipt = transactionInfo.receipt
        else {
            return .init(sentDate: nil, status: .pending)
        }
        
        var sentDate: Date?
        if let blockHash = details.blockHash {
            sentDate = try? await ethApiService.requestWeb3 { web3 in
                try await web3.eth.block(by: blockHash).timestamp
            }.get()
        }
        
        return await .init(
            sentDate: sentDate,
            status: getStatus(details: details, transaction: transaction, receipt: receipt)
        )
    }
}

private extension EthWalletService {
    struct EthTransactionInfo: Sendable {
        var details: Web3Core.TransactionDetails?
        var receipt: TransactionReceipt?
    }

    enum EthTransactionInfoElement: Sendable {
        case details(Web3Core.TransactionDetails)
        case receipt(TransactionReceipt)
    }
    
    func getTransactionInfo(hash: String, web3: Web3) async throws -> EthTransactionInfo {
        try await withThrowingTaskGroup(
            of: EthTransactionInfoElement.self,
            returning: Atomic<EthTransactionInfo>.self
        ) { group in
            group.addTask(priority: .userInitiated) { @Sendable in
                .details(try await web3.eth.transactionDetails(hash))
            }
            
            group.addTask(priority: .userInitiated) { @Sendable in
                .receipt(try await web3.eth.transactionReceipt(hash))
            }
            
            return try await group.reduce(
                into: .init(wrappedValue: .init())
            ) { result, value in
                switch value {
                case let .receipt(receipt):
                    result.wrappedValue.receipt = receipt
                case let .details(details):
                    result.wrappedValue.details = details
                }
            }
        }.wrappedValue
    }
    
    func getStatus(
        details: Web3Core.TransactionDetails,
        transaction: CoinTransaction,
        receipt: TransactionReceipt
    ) async -> TransactionStatus {
        let status = receipt.status.asTransactionStatus()
        guard status == .success else { return status }
        
        let eth = details.transaction
        
        // MARK: Check addresses
        
        var realSenderAddress = eth.sender?.address ?? ""
        var realRecipientAddress = eth.to.address
        
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
        
        guard eth.sender?.address.caseInsensitiveCompare(realSenderAddress) == .orderedSame else {
            return .inconsistent(.senderCryptoAddressMismatch(tokenSymbol))
        }
        
        guard eth.to.address.caseInsensitiveCompare(realRecipientAddress) == .orderedSame else {
            return .inconsistent(.recipientCryptoAddressMismatch(tokenSymbol))
        }
        
        if transaction.isOutgoing {
            guard ethWallet?.address.caseInsensitiveCompare(eth.sender?.address ?? "") == .orderedSame else {
                return .inconsistent(.senderCryptoAddressMismatch(tokenSymbol))
            }
        } else {
            guard ethWallet?.address.caseInsensitiveCompare(eth.to.address) == .orderedSame else {
                return .inconsistent(.recipientCryptoAddressMismatch(tokenSymbol))
            }
        }
        
        // MARK: Compare amounts
        let realAmount = eth.value.asDecimal(exponent: EthWalletService.currencyExponent)
        
        guard let reported = reportedValue(for: transaction) else {
            return .inconsistent(.wrongAmount)
        }
        let min = reported - reported*0.005
        let max = reported + reported*0.005
        
        guard (min...max).contains(realAmount) else {
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

extension TransactionReceipt.TXStatus {
    func asTransactionStatus() -> TransactionStatus {
        switch self {
        case .ok:
            return .success
            
        case .failed:
            return .failed
            
        case .notYetProcessed:
            return .registered
        }
    }
}
