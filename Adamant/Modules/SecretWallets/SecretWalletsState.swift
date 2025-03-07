//
//  SecretWalletsState.swift
//  Adamant
//
//  Created by Dmitrij Meidus on 28.02.25.
//  Copyright © 2025 Adamant. All rights reserved.
//

import Foundation

extension SecretWalletsAlertMenuView {
    struct SecretWalletsState: Equatable {
        var wallets: [WalletItem]
        var currentActiveIndex: Int
        
        static let `default` = Self(wallets: [], currentActiveIndex: -1)
    }
    
    struct WalletItem: Equatable, Identifiable {
        let id = UUID()
        let name: String
    }
}
