//
//  SecretWalletsState.swift
//  Adamant
//
//  Created by Dmitrij Meidus on 12.03.25.
//  Copyright © 2025 Adamant. All rights reserved.
//

import Foundation

struct SecretWalletsState: Equatable {
    var wallets: [WalletItem]
    var currentActiveIndex: Int
    
    var currentWallet: WalletItem? {
        guard currentActiveIndex >= 0 else { return nil }
        return wallets[currentActiveIndex]
    }
    
    static let `default` = Self(
        wallets: [WalletItem(
            name: String.localized(
                "SecretWallets.Menu.Regular",
                comment: "Secret wallet menu: regular wallet"
            )
        )],
        currentActiveIndex: 0
    )
}

struct WalletItem: Equatable, Identifiable {
    let id = UUID()
    let name: String
}
