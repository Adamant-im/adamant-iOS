//
//  EthWalletService+RichMessageProviderWithStatusCheck.swift
//  Adamant
//
//  Created by Anokhov Pavel on 06.10.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import web3swift
import Web3Core
import CommonKit

extension EthWalletService: RichMessageProviderWithStatusCheck {
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
        
        let transactionInfo: EthTransactionInfo
        
        do {
            transactionInfo = try await ethApiService.requestWeb3 { [weak self] web3 in
                guard let self = self else { throw WalletServiceError.internalError(.unknownError) }
                return try await getTransactionInfo(hash: hash, web3: web3)
            }.get()
        } catch _ as URLError {
            return .init(sentDate: nil, status: .noNetwork)
        } catch {
            return .init(sentDate: nil, status: .pending)
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
        
        return .init(
            sentDate: sentDate,
            status: getStatus(details: details, transaction: transaction, receipt: receipt)
        )
    }
}

private extension EthWalletService {
    struct EthTransactionInfo {
        var details: Web3Core.TransactionDetails?
        var receipt: TransactionReceipt?
    }

    enum EthTransactionInfoElement {
        case details(Web3Core.TransactionDetails)
        case receipt(TransactionReceipt)
    }
    
    func getTransactionInfo(hash: String, web3: Web3) async throws -> EthTransactionInfo {
        try await withThrowingTaskGroup(
            of: EthTransactionInfoElement.self,
            returning: EthTransactionInfo.self
        ) { group in
            group.addTask(priority: .userInitiated) {
                .details(try await web3.eth.transactionDetails(hash))
            }
            
            group.addTask(priority: .userInitiated) {
                .receipt(try await web3.eth.transactionReceipt(hash))
            }
            
            return try await group.reduce(into: .init()) { result, value in
                switch value {
                case let .receipt(receipt):
                    result.receipt = receipt
                case let .details(details):
                    result.details = details
                }
            }
        }
    }
    
    func getStatus(
        details: Web3Core.TransactionDetails,
        transaction: CoinTransaction,
        receipt: TransactionReceipt
    ) -> TransactionStatus {
        let status = receipt.status.asTransactionStatus()
        guard status == .success else { return status }
        
        let eth = details.transaction
        
        // MARK: Check addresses
        if transaction.isOutgoing {
            guard let sender = eth.sender?.address,
                  let id = self.ethWallet?.address,
                  sender == id
            else {
                return .inconsistent
            }
        } else {
            guard let id = self.ethWallet?.address,
                  eth.to.address == id
            else {
                return .inconsistent
            }
        }
        
        // MARK: Compare amounts
        let realAmount = eth.value.asDecimal(exponent: EthWalletService.currencyExponent)
        
        guard let reported = reportedValue(for: transaction) else {
            return .inconsistent
        }
        let min = reported - reported*0.005
        let max = reported + reported*0.005
        
        guard (min...max).contains(realAmount) else {
            return .inconsistent
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
