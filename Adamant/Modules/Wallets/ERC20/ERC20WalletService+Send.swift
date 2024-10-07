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
@preconcurrency import Web3Core
import CommonKit

extension ERC20WalletService: WalletServiceTwoStepSend {
    typealias T = CodableTransaction
    
    // MARK: Create & Send
    func createTransaction(
        recipient: String,
        amount: Decimal,
        fee: Decimal,
        comment: String?
    ) async throws -> CodableTransaction {
        guard let ethWallet = ethWallet else {
            throw WalletServiceError.notLogged
        }
        
        guard let ethRecipient = EthereumAddress(recipient) else {
            throw WalletServiceError.accountNotFound
        }
        
        guard let keystoreManager = await erc20ApiService.keystoreManager else {
            throw WalletServiceError.internalError(message: "Failed to get web3.provider.KeystoreManager", error: nil)
        }
        
        let provider = try await erc20ApiService.requestWeb3 { web3 in web3.provider }.get()
        let resolver = PolicyResolver(provider: provider)
        
        // MARK: Create transaction
        
        var tx = try await erc20ApiService.requestERC20(token: token) { erc20 in
            try await erc20.transfer(
                from: ethWallet.ethAddress,
                to: ethRecipient,
                amount: "\(amount)"
            ).transaction
        }.get()
        
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
    }
    
    func sendTransaction(_ transaction: CodableTransaction) async throws {
        guard let txEncoded = transaction.encode() else {
            throw WalletServiceError.internalError(message: .adamant.sharedErrors.unknownError, error: nil)
        }
        
        _ = try await erc20ApiService.requestWeb3 { web3 in
            try await web3.eth.send(raw: txEncoded)
        }.get()
    }
}
