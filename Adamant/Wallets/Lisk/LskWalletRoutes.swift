//
//  LskWalletRoutes.swift
//  Adamant
//
//  Created by Anton Boyarkin on 27/11/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

extension AdamantScene.Wallets {
    struct Lisk {
        /// Wallet preview
        static let wallet = AdamantScene(identifier: "LskWalletViewController") { r in
            let c = LskWalletViewController(nibName: "WalletViewControllerBase", bundle: nil)
            c.dialogService = r.resolve(DialogService.self)
            return c
        }
    }
}
