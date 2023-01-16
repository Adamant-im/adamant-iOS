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
    func create(recipient: String, amount: Decimal, completion: @escaping (WalletServiceResult<DashWalletService.T>) -> Void) {
        if let lastTransaction = self.lastTransactionId {
            self.getTransaction(by: lastTransaction) { result in
                switch result {
                case .success(let transaction):
                    if let confirmations = transaction.confirmations, confirmations >= 1 {
                        self.createTransaction(recipient: recipient, amount: amount, completion: completion)
                    } else {
                        completion(.failure(error: WalletServiceError.internalError(message: "WAIT_FOR_COMPLETION", error: nil)))
                    }
                case .failure:
                    completion(.failure(error: WalletServiceError.internalError(message: "WAIT_FOR_COMPLETION", error: nil)))
                }
            }
        } else {
            self.createTransaction(recipient: recipient, amount: amount, completion: completion)
        }
    }
    
    func createTransaction(recipient: String, amount: Decimal, completion: @escaping (WalletServiceResult<BitcoinKit.Transaction>) -> Void) {
        // MARK: 1. Prepare
        guard let wallet = self.dashWallet else {
            completion(.failure(error: .notLogged))
            return
        }
        
        let changeAddress = wallet.publicKey.toCashaddr()
        let key = wallet.privateKey
        
        guard let toAddress = try? LegacyAddress(recipient, for: self.network) else {
            completion(.failure(error: .accountNotFound))
            return
        }
        
        let rawAmount = NSDecimalNumber(decimal: amount * DashWalletService.multiplier).uint64Value
        let fee = NSDecimalNumber(decimal: self.transactionFee * DashWalletService.multiplier).uint64Value
        
        // MARK: 2. Search for unspent transactions
        getUnspentTransactions { result in
            switch result {
            case .success(let utxos):
                // MARK: 3. Check if we have enought money
                let totalAmount: UInt64 = UInt64(utxos.reduce(0) { $0 + $1.output.value })
                guard totalAmount >= rawAmount + fee else { // This shit can crash BitcoinKit
                    completion(.failure(error: .notEnoughMoney))
                    break
                }
                
                // MARK: 4. Create local transaction
                let transaction = BitcoinKit.Transaction.createNewTransaction(toAddress: toAddress, amount: rawAmount, fee: fee, changeAddress: changeAddress, utxos: utxos, keys: [key])
                completion(.success(result: transaction))
                
            case .failure:
                completion(.failure(error: .notEnoughMoney))
            }
        }
    }
    
    func sendTransaction(_ transaction: BitcoinKit.Transaction, completion: @escaping (WalletServiceResult<String>) -> Void) {
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
        AF.request(endpoint, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers).responseData(queue: defaultDispatchQueue) { response in
            
            switch response.result {
            case .success(let data):
                do {
                    let response = try JSONDecoder().decode(BTCRPCServerResponce<String>.self, from: data)
                    
                    if let result = response.result {
                        self.lastTransactionId = transaction.txID
                        completion(.success(result: result))
                    } else if let error = response.error?.message {
                        if error.lowercased().contains("16: tx-txlock-conflict") {
                            completion(.failure(error: .internalError(message: String.adamantLocalized.sharedErrors.walletFrezzed, error: nil)))
                        } else {
                            completion(.failure(error: .internalError(message: error, error: nil)))
                        }
                    } else {
                        completion(.failure(error: .internalError(message: "DASH Wallet: not valid response", error: nil)))
                    }
                } catch {
                    completion(.failure(error: .internalError(message: "DASH Wallet: not valid response", error: nil)))
                }
                
            case .failure(let error):
                completion(.failure(error: .remoteServiceError(message: error.localizedDescription)))
            }
        }
    }
}
