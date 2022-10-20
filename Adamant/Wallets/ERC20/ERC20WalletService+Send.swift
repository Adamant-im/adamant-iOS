//
//  ERC20WalletService+Send.swift
//  Adamant
//
//  Created by Anton Boyarkin on 06/07/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import UIKit
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

        guard
            let decimals = token?.decimals,
            let bigUIntAmount = Web3.Utils.parseToBigUInt("\(amount)", decimals: decimals) else {
            completion(.failure(error: .invalidAmount(amount)))
            return
        }

        guard let keystoreManager = web3?.provider.attachedKeystoreManager else {
            completion(.failure(error: .internalError(message: "Failed to get web3.provider.KeystoreManager", error: nil)))
            return
        }

        // MARK: Go background
        defaultDispatchQueue.async {
            // MARK: 2. Create contract
            var options = TransactionOptions.defaultOptions
            options.from = ethWallet.ethAddress
            options.gasLimit = .automatic
            options.gasPrice = .automatic

            guard let contract = self.contract else {
                completion(.failure(error: .internalError(message: "ETH Wallet: Send - contract loading error", error: nil)))
                return
            }
            
            guard let intermediate = contract.write("transfer", parameters: [ethRecipient, bigUIntAmount] as [AnyObject], extraData: Data(), transactionOptions: options) else {
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
            self.web3?.eth.sendRawTransactionPromise(transaction).done { result in
                completion(.success(result: result.hash))
            }.catch { error in
                completion(.failure(error: .internalError(message: error.localizedDescription, error: error)))
            }
        }
    }
}
