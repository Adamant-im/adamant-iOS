//
//  DashWalletService+Send.swift
//  Adamant
//
//  Created by Anton Boyarkin on 26/05/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import UIKit
import BitcoinKit
import Alamofire

extension DashWalletService: WalletServiceTwoStepSend {
    typealias T = BitcoinKit.Transaction
    
    func transferViewController() -> UIViewController {
        guard let vc = router.get(scene: AdamantScene.Wallets.Dash.transfer) as? DashTransferViewController else {
            fatalError("Can't get DashTransferViewController")
        }
        
        vc.service = self
        return vc
    }
    
    // MARK: Create & Send
    func create(recipient: String, amount: Decimal) async throws -> BitcoinKit.Transaction {
        guard let lastTransaction = self.lastTransactionId else {
            return try await  createTransaction(recipient: recipient, amount: amount)
        }
        
        do {
            let transaction = try await getTransaction(by: lastTransaction)
            
            guard let confirmations = transaction.confirmations,
                  confirmations >= 1
            else {
                throw WalletServiceError.internalError(message: "WAIT_FOR_COMPLETION", error: nil)
            }
            
            return try await createTransaction(recipient: recipient, amount: amount)
        } catch {
            throw error
        }
    }
    
    func createTransaction(recipient: String, amount: Decimal) async throws -> BitcoinKit.Transaction {
        // MARK: 1. Prepare
        guard let wallet = self.dashWallet else {
            throw WalletServiceError.notLogged
        }
        
        let changeAddress = wallet.publicKey.toCashaddr()
        let key = wallet.privateKey
        
        guard let toAddress = try? LegacyAddress(recipient, for: self.network) else {
            throw WalletServiceError.accountNotFound
        }
        
        let rawAmount = NSDecimalNumber(decimal: amount * DashWalletService.multiplier).uint64Value
        let fee = NSDecimalNumber(decimal: self.transactionFee * DashWalletService.multiplier).uint64Value
        
        // MARK: 2. Search for unspent transactions
        do {
            let utxos = try await getUnspentTransactions()
            
            // MARK: 3. Check if we have enought money
            let totalAmount: UInt64 = UInt64(utxos.reduce(0) { $0 + $1.output.value })
            guard totalAmount >= rawAmount + fee else { // This shit can crash BitcoinKit
                throw WalletServiceError.notEnoughMoney
            }
            
            // MARK: 4. Create local transaction
            let transaction = BitcoinKit.Transaction.createNewTransaction(toAddress: toAddress, amount: rawAmount, fee: fee, changeAddress: changeAddress, utxos: utxos, keys: [key])
            return transaction
        } catch {
            throw error
        }
    }
    
    func sendTransaction(_ transaction: BitcoinKit.Transaction) async throws -> String {
        guard let endpoint = DashWalletService.nodes.randomElement()?.asURL() else {
            fatalError("Failed to get DASH endpoint URL")
        }
        
        let txHex = transaction.serialized().hex
        
        // Headers
        let headers: HTTPHeaders = [
            "Content-Type": "application/json"
        ]
        
        let parameters: Parameters = [
            "method": "sendrawtransaction",
            "params": [
                txHex
            ]
        ]
        
        // MARK: Sending request
        return try await withUnsafeThrowingContinuation { (continuation: UnsafeContinuation<String, Error>) in
            AF.request(endpoint, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers).responseData(queue: defaultDispatchQueue) { response in
                
                switch response.result {
                case .success(let data):
                    do {
                        let response = try JSONDecoder().decode(BTCRPCServerResponce<String>.self, from: data)
                        
                        if let result = response.result {
                            self.lastTransactionId = transaction.txID
                            continuation.resume(returning: result)
                        } else if let error = response.error?.message {
                            if error.lowercased().contains("16: tx-txlock-conflict") {
                                continuation.resume(throwing: WalletServiceError.internalError(message: String.adamantLocalized.sharedErrors.walletFrezzed, error: nil))
                            } else {
                                continuation.resume(throwing: WalletServiceError.internalError(message: error, error: nil))
                            }
                        } else {
                            continuation.resume(throwing: WalletServiceError.internalError(message: "DASH Wallet: not valid response", error: nil))
                        }
                    } catch {
                        continuation.resume(throwing: WalletServiceError.internalError(message: "DASH Wallet: not valid response", error: nil))
                    }
                    
                case .failure(let error):
                    continuation.resume(throwing: WalletServiceError.remoteServiceError(message: error.localizedDescription))
                }
            }
        }
    }
}
