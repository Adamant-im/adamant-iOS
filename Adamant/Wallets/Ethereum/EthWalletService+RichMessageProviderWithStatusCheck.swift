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
    func statusForTransactionBy(hash: String, date: Date?, amount: Double, isOutgoing: Bool, completion: @escaping (WalletServiceResult<TransactionStatus>) -> Void) {
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
        
        do {
            let receipt = try web3.eth.getTransactionReceiptPromise(hash).wait()
            var status = receipt.status.asTransactionStatus()
            
            if status == .success, isOutgoing == false, let date = date, let blockNumber = details.blockNumber  {
                let start = date.addingTimeInterval(-60 * 5)
                let end = date.addingTimeInterval(60 * 5)
                let range = start...end
                
                let block = try web3.eth.getBlockByNumberPromise(blockNumber).wait()
                
                let transaction = details.transaction.asEthTransaction(date: block.timestamp, gasUsed: receipt.gasUsed, blockNumber: "0", confirmations: "0", receiptStatus: receipt.status, isOutgoing: isOutgoing)
                
                if transaction.recipientAddress != self.ethWallet?.address ||
                    !range.contains(transaction.dateValue ?? Date()) ||
                    amount != transaction.amountValue.doubleValue {
                    status = .warning
                }
            }
        
            completion(.success(result: status))
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
        } catch {
            completion(.failure(error: WalletServiceError.internalError(message: "Failed to get transaction", error: error)))
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
