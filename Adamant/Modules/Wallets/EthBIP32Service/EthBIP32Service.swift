//
//  EthPIP32Service.swift
//  Adamant
//
//  Created by Владимир Клевцов on 30.1.25..
//  Copyright © 2025 Adamant. All rights reserved.
//
import Web3Core

protocol EthBIP32ServiceProtocol {
    func keyStore(passphrase: String) async throws -> BIP32Keystore
}

actor EthBIP32Service: EthBIP32ServiceProtocol {
    private var passphrase: String?
    private var keystore: BIP32Keystore?
    
    private var ethApiService: EthApiServiceProtocol
    
    init(ethApiService: EthApiServiceProtocol) {
        self.ethApiService = ethApiService
    }
    func keyStore(passphrase: String) async throws -> BIP32Keystore {
        if let keystore = self.keystore, passphrase == self.passphrase {
            return keystore
        }
        do {
            guard let store = try BIP32Keystore(mnemonics: passphrase,
                                                password: EthWalletService.walletPassword,
                                                mnemonicsPassword: "",
                                                language: .english,
                                                prefixPath: EthWalletService.walletPath) else {
                throw WalletServiceError.internalError(message: "ETH Wallet: failed to create Keystore", error: nil)
            }
            self.passphrase = passphrase
            self.keystore = store
            await ethApiService.setKeystoreManager(.init([store]))
            return store
        }
    }
}
