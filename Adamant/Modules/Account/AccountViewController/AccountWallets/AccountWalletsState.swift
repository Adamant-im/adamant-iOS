//
//  AccountWalletsState.swift
//  Adamant
//
//  Created by Dmitrij Meidus on 29.01.25.
//  Copyright © 2025 Adamant. All rights reserved.
//

extension AccountViewController {
    struct AccountWalletsState: Equatable {
        var wallets: [WalletCollectionViewCell.Model]
        
        static let `default` = Self(wallets: [])
    }
}
