//
// WalletServiceCompose.swift
// Adamant
//
// Created by Stanislav Jelezoglo on 01.12.2023.
// Copyright © 2023 Adamant. All rights reserved.
//

import Foundation

protocol WalletServiceCompose: Sendable {
    func getWallet(by type: String) -> WalletService?
    func getWallets() -> [WalletService]
}

protocol PublicWalletServiceCompose: WalletServiceCompose {}

protocol SecretWalletServiceCompose: WalletServiceCompose {}

struct AdamantPublicWalletServiceCompose: PublicWalletServiceCompose {
    private let wallets: [String: WalletService]
    
    init(wallets: [WalletCoreProtocol]) {
        self.wallets = Dictionary(uniqueKeysWithValues: wallets.map { wallet in
            (wallet.dynamicRichMessageType, WalletService(core: wallet))
        })
    }
    
    func getWallet(by type: String) -> WalletService? {
        wallets[type]
    }
    
    func getWallets() -> [WalletService] {
        Array(wallets.values)
    }
}

struct AdamantSecretWalletServiceCompose: SecretWalletServiceCompose {
    private let wallets: [String: WalletService]
    
    init(wallets: [WalletCoreProtocol]) {
        self.wallets = Dictionary(uniqueKeysWithValues: wallets.map { wallet in
            (wallet.dynamicRichMessageType, WalletService(core: wallet))
        })
    }
    
    func getWallet(by type: String) -> WalletService? {
        wallets[type]
    }
    
    func getWallets() -> [WalletService] {
        Array(wallets.values)
    }
}
