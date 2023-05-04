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

extension EthWalletService: RichMessageProviderWithStatusCheck {
    func statusInfoFor(transaction: RichMessageTransaction) async -> TransactionStatusInfo {
        guard
            let web3 = await web3,
            let hash = transaction.getRichValue(for: RichContentKeys.transfer.hash)
        else {
            return .init(sentDate: nil, status: .inconsistent)
        }
        
        let transactionInfo: EthTransactionInfo
        
        do {
            transactionInfo = try await getTransactionInfo(hash: hash, web3: web3)
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
            sentDate = try? await web3.eth.block(by: blockHash).timestamp
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
        transaction: RichMessageTransaction,
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
        
        guard let raw = transaction.getRichValue(for: RichContentKeys.transfer.amount),
              let reported = AdamantBalanceFormat.deserializeBalance(from: raw) else {
            return .inconsistent
        }
        let min = reported - reported*0.005
        let max = reported + reported*0.005
        
        guard (min...max).contains(realAmount) else {
            return .inconsistent
        }
        
        return .success
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
