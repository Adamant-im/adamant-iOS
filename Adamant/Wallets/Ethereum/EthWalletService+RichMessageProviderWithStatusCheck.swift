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
    func statusFor(transaction: RichMessageTransaction) async throws -> TransactionStatus{
        guard let web3 = await self.web3,
              let hash = transaction.richContent?[RichContentKeys.transfer.hash]
        else {
            throw WalletServiceError.internalError(message: "Failed to get transaction hash", error: nil)
        }
        
        // MARK: Get transaction
        
        let details: Web3Core.TransactionDetails
        do {
            details = try await web3.eth.transactionDetails(hash)
        } catch let error as Web3Error {
            guard transaction.transactionStatus == .notInitiated else {
                throw error.asWalletServiceError()
            }
            return .pending
        } catch {
            throw WalletServiceError.internalError(message: "Failed to get transaction", error: error)
        }
        
        let status: TransactionStatus
        let transactionDate: Date
        do {
            let receipt = try await web3.eth.transactionReceipt(hash)
            status = receipt.status.asTransactionStatus()
            guard status != .pending else {
                return .pending
            }
            
            guard status == .success,
                  let blockHash = details.blockHash,
                  let date = transaction.date as Date?
            else {
                return status
            }
            
            transactionDate = date
            _ = try await web3.eth.block(by: blockHash)
        } catch let error as Web3Error {
            switch error {
                // Transaction not delivired yet
            case .inputError, .nodeError:
                return .pending
                
            default:
                throw error.asWalletServiceError()
            }
        } catch {
            throw WalletServiceError.internalError(message: "Failed to get transaction", error: error)
        }
        
        let start = transactionDate.addingTimeInterval(-60 * 5)
        let end = transactionDate.addingTimeInterval(self.consistencyMaxTime)
        let range = start...end
        let eth = details.transaction
        
        // MARK: Check addresses
        if transaction.isOutgoing {
            guard let sender = eth.sender?.address,
                  let id = self.ethWallet?.address,
                  sender == id
            else {
                return .warning
            }
        } else {
            guard let id = self.ethWallet?.address,
                  eth.to.address == id
            else {
                return.warning
            }
        }
        
        // MARK: Check dates
        guard range.contains(transaction.dateValue ?? Date()) else {
            return .warning
        }
        
        // MARK: Compare amounts
        let realAmount = eth.value.asDecimal(exponent: EthWalletService.currencyExponent)
        
        guard let raw = transaction.richContent?[RichContentKeys.transfer.amount], let reported = AdamantBalanceFormat.deserializeBalance(from: raw) else {
            return .warning
        }
        let min = reported - reported*0.005
        let max = reported + reported*0.005
        
        guard (min...max).contains(realAmount) else {
            return .warning
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
            return .pending
        }
    }
}
