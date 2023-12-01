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
    private let wallets: [WalletService]
    
    init(wallets: [WalletCoreProtocol], coreDataStack: CoreDataStack) {
        self.wallets = wallets.map {
            WalletService(core: $0, coreDataStack: coreDataStack)
        }
    }
    
    func getWallet(by type: String) -> WalletService? {
        wallets.first(where: { $0.core.dynamicRichMessageType == type })
    }
    
    func getWallets() -> [WalletService] {
        wallets
    }
}
