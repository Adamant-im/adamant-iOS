//
//  EthWalletService+Send.swift
//  Adamant
//
//  Created by Anokhov Pavel on 21.08.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
@preconcurrency import web3swift
import struct BigInt.BigUInt
@preconcurrency import Web3Core
import CommonKit

extension CodableTransaction: RawTransaction {
    var txHash: String? {
        guard let hash = hash?.hex else { return nil }
        return "0x\(hash)"
    }
}

extension EthWalletService: WalletServiceTwoStepSend {
	typealias T = CodableTransaction
    
    func createTransaction(
        recipient: String,
        amount: Decimal,
        fee: Decimal,
        comment: String?
    ) async throws -> CodableTransaction {
        try await ethApiService.requestWeb3(waitsForConnectivity: false) { [weak self] web3 in
            guard let self = self else { throw WalletServiceError.internalError(.unknownError) }
            return try await createTransaction(recipient: recipient, amount: amount, web3: web3)
        }.get()
    }
	
    // MARK: Create & Send
    private func createTransaction(
        recipient: String,
        amount: Decimal,
        web3: Web3
    ) async throws -> CodableTransaction {
        guard let ethWallet = ethWallet else {
            throw WalletServiceError.notLogged
        }
        
        guard let ethRecipient = EthereumAddress(recipient) else {
            throw WalletServiceError.accountNotFound
        }
        
        guard let bigUIntAmount = Utilities.parseToBigUInt(String(format: "%.18f", amount.doubleValue), units: .ether) else {
            throw WalletServiceError.invalidAmount(amount)
        }
        
        guard let keystoreManager = web3.provider.attachedKeystoreManager else {
            throw WalletServiceError.internalError(message: "Failed to get web3.provider.KeystoreManager", error: nil)
        }
        
        let provider = web3.provider
        
        // MARK: Create contract
        
        guard let contract = web3.contract(Web3.Utils.coldWalletABI, at: ethRecipient),
              var tx = contract.createWriteOperation()?.transaction
        else {
            throw WalletServiceError.internalError(message: "ETH Wallet: Send - contract loading error", error: nil)
        }
        
        tx.from = ethWallet.ethAddress
        tx.to = ethRecipient
        tx.value = bigUIntAmount
        
        await calculateFee(for: ethRecipient)
        
        let resolver = PolicyResolver(provider: provider)
        let policies: Policies = Policies(
            gasLimitPolicy: .manual(gasLimit),
            gasPricePolicy: .manual(gasPrice)
        )
        
        do {
            try await resolver.resolveAll(for: &tx, with: policies)
            
            try Web3Signer.signTX(transaction: &tx,
                                  keystore: keystoreManager,
                                  account: ethWallet.ethAddress,
                                  password: EthWalletService.walletPassword
            )
            
            return tx
        } catch {
            throw WalletServiceError.internalError(message: "Transaction sign error", error: error)
        }
    }
    
    func sendTransaction(_ transaction: CodableTransaction) async throws {
        guard let txEncoded = transaction.encode() else {
            throw WalletServiceError.internalError(message: .adamant.sharedErrors.unknownError, error: nil)
        }
        
        _ = try await ethApiService.requestWeb3(waitsForConnectivity: false) { web3 in
            try await web3.eth.send(raw: txEncoded)
        }.get()
    }
}
