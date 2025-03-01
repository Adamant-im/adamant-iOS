//
//  EthPIP32Service.swift
//  Adamant
//
//  Created by Владимир Клевцов on 30.1.25..
//  Copyright © 2025 Adamant. All rights reserved.
//
import Web3Core

protocol EthBIP32ServiceProtocol {
    func keyStore(passphrase: String, withPassword password: String) async throws -> BIP32Keystore
}

// TODO: Return optimization
struct EthBIP32Service: EthBIP32ServiceProtocol {
    private var ethApiService: EthApiServiceProtocol
    
    init(ethApiService: EthApiServiceProtocol) {
        self.ethApiService = ethApiService
    }
    
    func keyStore(passphrase: String, withPassword password: String) async throws -> BIP32Keystore {
        do {
            guard let store = try BIP32Keystore(mnemonics: passphrase,
                                                password: EthWalletService.walletPassword,
                                                mnemonicsPassword: password,
                                                language: .english,
                                                prefixPath: EthWalletService.walletPath) else {
                throw WalletServiceError.internalError(message: "ETH Wallet: failed to create Keystore", error: nil)
            }
            await ethApiService.setKeystoreManager(.init([store]))
            return store
        }
    }
}
