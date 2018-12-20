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
    func statusForTransactionBy(hash: String, date: Date?, completion: @escaping (WalletServiceResult<TransactionStatus>) -> Void) {
        do {
            _ = try web3.eth.getTransactionDetailsPromise(hash).wait()
        } catch let error as Web3Error {
            completion(.failure(error: error.asWalletServiceError()))
            return
        } catch {
            completion(.failure(error: WalletServiceError.internalError(message: "Failed to get transaction", error: error)))
            return
        }
        
        do {
            let receipt = try web3.eth.getTransactionReceiptPromise(hash).wait()
            completion(.success(result: receipt.status.asTransactionStatus()))
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
