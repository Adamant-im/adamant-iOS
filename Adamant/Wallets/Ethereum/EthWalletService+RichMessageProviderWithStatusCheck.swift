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
    func statusFor(transaction: RichMessageTransaction, completion: @escaping (WalletServiceResult<TransactionStatus>) -> Void) {
        Task {
            guard let web3 = await self.web3,
                  let hash = transaction.richContent?[RichContentKeys.transfer.hash],
                  let txHash = hash.data(using: .utf8)
            else {
                completion(.failure(error: WalletServiceError.internalError(message: "Failed to get transaction hash", error: nil)))
                return
            }
            
            // MARK: Get transaction
            
            let details: Web3Core.TransactionDetails
            do {
                details = try await web3.eth.transactionDetails(txHash)
            } catch let error as Web3Error {
                guard transaction.transactionStatus == .notInitiated else {
                    completion(.failure(error: error.asWalletServiceError()))
                    return
                }
                completion(.success(result: .pending))
                return
            } catch {
                completion(.failure(error: WalletServiceError.internalError(message: "Failed to get transaction", error: error)))
                return
            }
            
            let status: TransactionStatus
            let transactionDate: Date
            do {
                let receipt = try await web3.eth.transactionReceipt(txHash)
                status = receipt.status.asTransactionStatus()
                guard status != .pending else {
                    completion(.success(result: .pending))
                    return
                }

                guard status == .success,
                      let blockHash = details.blockHash,
                      let date = transaction.date as Date?
                else {
                    completion(.success(result: status))
                    return
                }
                
                transactionDate = date
                _ = try await web3.eth.block(by: blockHash)
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
