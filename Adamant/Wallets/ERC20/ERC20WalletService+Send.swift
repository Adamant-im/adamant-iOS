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
            guard let ethWallet = ethWallet,
                  let erc20 = erc20
            else {
                completion(.failure(error: .notLogged))
                return
            }
            
            guard let ethRecipient = EthereumAddress(recipient) else {
                completion(.failure(error: .accountNotFound))
                return
            }
            
            guard let web3 = await web3 else {
                completion(.failure(error: .internalError(message: "Failed to get web3", error: nil)))
                return
            }
            
            guard let keystoreManager = web3.provider.attachedKeystoreManager else {
                completion(.failure(error: .internalError(message: "Failed to get web3.provider.KeystoreManager", error: nil)))
                return
            }
            
            let provider = web3.provider
            let resolver = PolicyResolver(provider: provider)
            
            // MARK: Create transaction
            
            do {
                var tx = try await erc20.transfer(from: ethWallet.ethAddress,
                                                  to: ethRecipient,
                                                  amount: String(format: "%.18f", amount.doubleValue)
                ).transaction
                
                try await resolver.resolveAll(for: &tx)
                
                try Web3Signer.signTX(transaction: &tx,
                                      keystore: keystoreManager,
                                      account: ethWallet.ethAddress,
                                      password: ERC20WalletService.walletPassword
                )
                
                completion(.success(result: tx))
            } catch {
                completion(.failure(error: WalletServiceError.internalError(message: "Transaction sign error", error: error)))
            }
        }
    }
    
    func sendTransaction(_ transaction: CodableTransaction, completion: @escaping (WalletServiceResult<String>) -> Void) {
        Task {
            guard let txEncoded = transaction.encode() else {
                completion(.failure(error: .internalError(message: "Unknown error", error: nil)))
                return
            }
            
            do {
                let result = try await web3?.eth.send(raw: txEncoded)
                completion(.success(result: result?.hash ?? ""))
            } catch {
                completion(.failure(error: .internalError(message: "Error: \(error.localizedDescription)", error: nil)))
            }
        }
    }
}
