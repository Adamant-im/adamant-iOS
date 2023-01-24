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
import Web3Core

extension ERC20WalletService: WalletServiceTwoStepSend {
    typealias T = CodableTransaction
    
    func transferViewController() -> UIViewController {
        guard let vc = router.get(scene: AdamantScene.Wallets.ERC20.transfer) as? ERC20TransferViewController else {
            fatalError("Can't get ERC20TransferViewController")
        }
        
        vc.service = self
        return vc
    }
    
    // MARK: Create & Send
    func createTransaction(recipient: String, amount: Decimal, completion: @escaping (WalletServiceResult<CodableTransaction>) -> Void) {
        Task {
            guard let ethWallet = ethWallet else {
                completion(.failure(error: .notLogged))
                return
            }
            
            guard let ethRecipient = EthereumAddress(recipient) else {
                completion(.failure(error: .accountNotFound))
                return
            }
            
            guard let bigUIntAmount = Utilities.parseToBigUInt(String(format: "%.18f", amount.doubleValue), units: .ether) else {
                completion(.failure(error: .invalidAmount(amount)))
                return
            }
            
            guard let keystoreManager = await web3?.provider.attachedKeystoreManager else {
                completion(.failure(error: .internalError(message: "Failed to get web3.provider.KeystoreManager", error: nil)))
                return
            }
            
            guard let provider = await web3?.provider else {
                completion(.failure(error: .internalError(message: "Failed to get web3.provider", error: nil)))
                return
            }
        
            // MARK: 2. Create contract
        
            var transaction: CodableTransaction = .emptyTransaction
            transaction.from = ethWallet.ethAddress
            transaction.to = ethRecipient
            transaction.value = bigUIntAmount
//            transaction.gasLimit = .automatic
//            transaction.gasPrice = .automatic
            
            
            let resolver = PolicyResolver(provider: provider)
            do {
                try await resolver.resolveAll(for: &transaction)
                // sign tx
                try Web3Signer.signTX(transaction: &transaction,
                                      keystore: keystoreManager,
                                      account: ethWallet.ethAddress,
                                      password: ""
                )
                completion(.success(result: transaction))
            } catch {
                completion(.failure(error: WalletServiceError.internalError(message: "Transaction sign error", error: error)))
            }
        }
    }
    
    func sendTransaction(_ transaction: CodableTransaction, completion: @escaping (WalletServiceResult<String>) -> Void) {
        Task {
            guard let txEncoded = transaction.encode() else { return }
            
            if let result = try await web3?.eth.send(raw: txEncoded) {
                completion(.success(result: result.hash))
            } else {
                completion(.failure(error: .internalError(message: "unknown error", error: nil)))
            }
        }
    }
}
