//
//  DogeWalletRoutes.swift
//  Adamant
//
//  Created by Anton Boyarkin on 05/03/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import Foundation

extension AdamantScene.Wallets {
    struct Doge {
        /// Wallet preview
        static let wallet = AdamantScene(identifier: "DogeWalletViewController") { r in
            let c = DogeWalletViewController(nibName: "WalletViewControllerBase", bundle: nil)
            c.dialogService = r.resolve(DialogService.self)
            return c
        }
    }
}
