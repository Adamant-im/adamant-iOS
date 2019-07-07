//
//  ERC20WalletService+Send.swift
//  Adamant
//
//  Created by Anton Boyarkin on 06/07/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import Foundation
import web3swift
import struct BigInt.BigUInt
import PromiseKit

extension ERC20WalletService: WalletServiceTwoStepSend {
    typealias T = EthereumTransaction
    
    func transferViewController() -> UIViewController {
        guard let vc = router.get(scene: AdamantScene.Wallets.ERC20.transfer) as? ERC20TransferViewController else {
            fatalError("Can't get ERC20TransferViewController")
        }
        
        vc.service = self
        return vc
    }
    
    
    // MARK: Create & Send
    func createTransaction(recipient: String, amount: Decimal, completion: @escaping (WalletServiceResult<EthereumTransaction>) -> Void) {
        // MARK: 1. Prepare
        guard let ethWallet = ethWallet else {
            completion(.failure(error: .notLogged))
            return
        }

        guard let ethRecipient = EthereumAddress(recipient) else {
            completion(.failure(error: .accountNotFound))
            return
        }

        guard let bigUIntAmount = Web3.Utils.parseToBigUInt(String(format: "%.18f", amount.doubleValue), units: .eth) else {
            completion(.failure(error: .invalidAmount(amount)))
            return
        }

        guard let keystoreManager = web3.provider.attachedKeystoreManager else {
            completion(.failure(error: .internalError(message: "Failed to get web3.provider.KeystoreManager", error: nil)))
            return
        }

        // MARK: Go background
        defaultDispatchQueue.async {
            // MARK: 2. Create contract
            var options = Web3Options.defaultOptions()
            options.from = ethWallet.ethAddress
            options.value = bigUIntAmount

            guard let contract = self.contract else {
                completion(.failure(error: .internalError(message: "ETH Wallet: Send - contract loading error", error: nil)))
                return
            }

            guard let estimatedGas = contract.method(options: options)?.estimateGas(options: nil).value else {
                completion(.failure(error: .internalError(message: "ETH Wallet: Send - retrieving estimated gas error", error: nil)))
                return
            }

            options.gasLimit = estimatedGas

            guard let gasPrice = self.web3.eth.getGasPrice().value else {
                completion(.failure(error: .internalError(message: "ETH Wallet: Send - retrieving gas price error", error: nil)))
                return
            }

            options.gasPrice = gasPrice
            
            guard let intermediate = contract.method("transfer", parameters: [ethRecipient, amount] as [AnyObject], extraData: Data(), options: options) else {
                completion(.failure(error: .internalError(message: "ETH Wallet: Send - create transaction issue", error: nil)))
                return
            }

            do {
                let transaction = try intermediate.assemblePromise().then { transaction throws -> Promise<EthereumTransaction> in
                    var trs = transaction
                    try Web3Signer.signTX(transaction: &trs, keystore: keystoreManager, account: ethWallet.ethAddress, password: "")
                    let promise = Promise<EthereumTransaction>.pending()
                    promise.resolver.fulfill(trs)
                    return promise.promise
                    }.wait()

                completion(.success(result: transaction))
            } catch {
                completion(.failure(error: WalletServiceError.internalError(message: "Transaction sign error", error: error)))
            }
        }
    }
    
    func sendTransaction(_ transaction: EthereumTransaction, completion: @escaping (WalletServiceResult<String>) -> Void) {
        defaultDispatchQueue.async {
            switch self.web3.eth.sendRawTransaction(transaction) {
            case .success(let result):
                completion(.success(result: result.hash))
                
            case .failure(let error):
                completion(.failure(error: error.asWalletServiceError()))
            }
        }
    }
//
//    func sendTokens(to recipient: String, amount: Decimal, completion: @escaping (WalletServiceResult<String>) -> Void) {
//        guard let address = wallet?.address, let walletAddress = EthereumAddress(address), let toAddress = EthereumAddress(recipient), let contract = self.contract else {
//            completion(.failure(error: .internalError(message: "ETH Wallet: Send - create transaction issue", error: nil)))
//            return
//        }
//
//        guard let bigUIntAmount = Web3.Utils.parseToBigUInt(String(format: "%.18f", amount.doubleValue), units: .eth) else {
//            completion(.failure(error: .invalidAmount(amount)))
//            return
//        }
//
//        var options = Web3Options.defaultOptions()
//        options.value = bigUIntAmount
//        options.from = walletAddress
//
//        let method = "transfer"
//
//        guard let estimatedGas = contract.method(options: options)?.estimateGas(options: nil).value else {
//            completion(.failure(error: .internalError(message: "ETH Wallet: Send - retrieving estimated gas error", error: nil)))
//            return
//        }
//
//        options.gasLimit = estimatedGas
//
//        guard let gasPrice = self.web3.eth.getGasPrice().value else {
//            completion(.failure(error: .internalError(message: "ETH Wallet: Send - retrieving gas price error", error: nil)))
//            return
//        }
//
//        options.gasPrice = gasPrice
//
//        let tx = contract.method(method, parameters: [toAddress, amount] as [AnyObject], extraData: Data(), options: options)
//
//        do {
//            let result = try tx?.callPromise().then({ result throws -> Promise<Bool> in
//                let value = result["0"] as! Bool
//
//                let promise = Promise<Bool>.pending()
//                promise.resolver.fulfill(value)
//                return promise.promise
//            }).wait()
//
//            if result == true {
//                print(tx?.transaction.txHash ?? "NO HASH - Fuckkkkkk!!!!!")
//
//                if let hash = tx?.transaction.txHash {
//                    completion(.success(result:hash))
//                } else {
//                    completion(.failure(error: WalletServiceError.internalError(message: "Transaction sending error", error: nil)))
//                }
//            } else {
//                completion(.failure(error: WalletServiceError.internalError(message: "Transaction sending error", error: nil)))
//            }
//        } catch {
//            completion(.failure(error: WalletServiceError.internalError(message: "Transaction sending error", error: error)))
//        }
//    }
}
