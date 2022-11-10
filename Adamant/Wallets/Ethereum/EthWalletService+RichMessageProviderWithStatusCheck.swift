//
//  EthWalletService+RichMessageProviderWithStatusCheck.swift
//  Adamant
//
//  Created by Anokhov Pavel on 06.10.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import web3swift

extension EthWalletService: RichMessageProviderWithStatusCheck {
    func statusFor(transaction: RichMessageTransaction, completion: @escaping (WalletServiceResult<TransactionStatus>) -> Void) {
        guard let web3 = self.web3, let hash = transaction.richContent?[RichContentKeys.transfer.hash] else {
            completion(.failure(error: WalletServiceError.internalError(message: "Failed to get transaction hash", error: nil)))
            return
        }
        
        // MARK: Get transaction
        
        let details: web3swift.TransactionDetails
        do {
            details = try web3.eth.getTransactionDetailsPromise(hash).wait()
        } catch let error as Web3Error {
            completion(.failure(error: error.asWalletServiceError()))
            return
        } catch {
            completion(.failure(error: WalletServiceError.internalError(message: "Failed to get transaction", error: error)))
            return
        }
        
        let status: TransactionStatus
        let transactionDate: Date
        do {
            let receipt = try web3.eth.getTransactionReceiptPromise(hash).wait()
            status = receipt.status.asTransactionStatus()
            
            guard status == .success, let blockNumber = details.blockNumber, let date = transaction.date as Date? else {
                completion(.success(result: status))
                return
            }
            
            transactionDate = date
            _ = try web3.eth.getBlockByNumberPromise(blockNumber).wait()
        } catch let error as Web3Error {
            let result: WalletServiceResult<TransactionStatus>
            
            switch error {
            // Transaction not delivired yet
            case .inputError, .nodeError:
                result = .success(result: .pending)
                
            default:
                result = .failure(error: error.asWalletServiceError())
            }
            
            completion(result)
            return
        } catch {
            completion(.failure(error: WalletServiceError.internalError(message: "Failed to get transaction", error: error)))
            return
        }
        
        let start = transactionDate.addingTimeInterval(-60 * 5)
        let end = transactionDate.addingTimeInterval(self.consistencyMaxTime)
        let range = start...end
        let eth = details.transaction
        
        // MARK: Check addresses
        if transaction.isOutgoing {
            guard let sender = eth.sender?.address, let id = self.ethWallet?.address, sender == id else {
                completion(.success(result: .warning))
                return
            }
        } else {
            guard let id = self.ethWallet?.address, eth.to.address == id else {
                completion(.success(result: .warning))
                return
            }
        }
        
        // MARK: Check dates
        guard range.contains(transaction.dateValue ?? Date()) else {
            completion(.success(result: .warning))
            return
        }
        
        // MARK: Compare amounts
        let realAmount = eth.value.asDecimal(exponent: EthWalletService.currencyExponent)

        guard let raw = transaction.richContent?[RichContentKeys.transfer.amount], let reported = AdamantBalanceFormat.deserializeBalance(from: raw) else {
            completion(.success(result: .warning))
            return
        }
        let min = reported - reported*0.005
        let max = reported + reported*0.005
        
        guard (min...max).contains(realAmount) else {
            completion(.success(result: .warning))
            return
        }
        
        completion(.success(result: .success))
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
