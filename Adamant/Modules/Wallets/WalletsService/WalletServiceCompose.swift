//
//  WalletServiceCompose.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 01.12.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation

protocol WalletServiceCompose {
    func getWallet(by type: String) -> WalletService?
    func getWallets() -> [WalletService]
}

struct AdamantWalletServiceCompose: WalletServiceCompose {
    private var wallets: [String: WalletService] = [:]
    
    init(wallets: [WalletCoreProtocol], coreDataStack: CoreDataStack) {
        let uniqueWallets = Array(Set(wallets.map { $0.dynamicRichMessageType })).compactMap { type in
            wallets.first(where: { $0.dynamicRichMessageType == type })
        }
        
        self.wallets = Dictionary(uniqueKeysWithValues: uniqueWallets.map { wallet in
            (wallet.dynamicRichMessageType, WalletService(core: wallet, coreDataStack: coreDataStack))
        })
    }
    
    func getWallet(by type: String) -> WalletService? {
        wallets[type]
    }
    
    func getWallets() -> [WalletService] {
        Array(wallets.values)
    }
}
