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
    func statusFor(transaction: RichMessageTransaction) async throws -> TransactionStatus {
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
        
        guard let messageDate = transaction.dateValue else { return .warning }
        
        let status: TransactionStatus
        let ethTxDate: Date
        
        do {
            let receipt = try await web3.eth.transactionReceipt(hash)
            status = receipt.status.asTransactionStatus()
            guard status != .pending else {
                return .pending
            }
            
            guard let blockHash = details.blockHash else {
                return .warning
            }
            
            guard status == .success else { return status }
            ethTxDate = try await web3.eth.block(by: blockHash).timestamp
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
                return .warning
            }
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
        
        // MARK: Check date
        let start = messageDate.addingTimeInterval(-60 * 5)
        let end = messageDate.addingTimeInterval(self.consistencyMaxTime)
        let dateRange = start...end
        
        return dateRange.contains(ethTxDate)
            ? .success
            : .inconsistent
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
