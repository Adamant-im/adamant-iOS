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
import CommonKit

extension ERC20WalletService: WalletServiceTwoStepSend {
    typealias T = CodableTransaction
    
    // MARK: Create & Send
    func createTransaction(recipient: String, amount: Decimal) async throws -> CodableTransaction {
        guard let ethWallet = ethWallet,
              let erc20 = erc20
        else {
            throw WalletServiceError.notLogged
        }
        
        guard let ethRecipient = EthereumAddress(recipient) else {
            throw WalletServiceError.accountNotFound
        }
        
        guard let web3 = await web3 else {
            throw WalletServiceError.internalError(message: "Failed to get web3", error: nil)
        }
        
        guard let keystoreManager = web3.provider.attachedKeystoreManager else {
            throw WalletServiceError.internalError(message: "Failed to get web3.provider.KeystoreManager", error: nil)
        }
        
        let provider = web3.provider
        let resolver = PolicyResolver(provider: provider)
        
        // MARK: Create transaction
        
        do {
            var tx = try await erc20.transfer(
                from: ethWallet.ethAddress,
                to: ethRecipient,
                amount: "\(amount)"
            ).transaction
            
            await calculateFee(for: ethRecipient)
            
            let policies: Policies = Policies(
                gasLimitPolicy: .manual(gasLimit),
                gasPricePolicy: .manual(gasPrice)
            )
            
            try await resolver.resolveAll(for: &tx, with: policies)
            
            try Web3Signer.signTX(
                transaction: &tx,
                keystore: keystoreManager,
                account: ethWallet.ethAddress,
                password: ERC20WalletService.walletPassword
            )
            
            return tx
        } catch {
            throw WalletServiceError.internalError(message: "Transaction sign error", error: error)
        }
    }
    
    func sendTransaction(_ transaction: CodableTransaction) async throws {
        guard let txEncoded = transaction.encode() else {
            throw WalletServiceError.internalError(message: String.adamant.sharedErrors.unknownError, error: nil)
        }
        
        do {
            _ = try await web3?.eth.send(raw: txEncoded)
        } catch {
            throw WalletServiceError.internalError(message: "Error: \(error.localizedDescription)", error: nil)
        }
    }
}