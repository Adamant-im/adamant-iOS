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
        
        /// List of Lisk transactions
        static let transactionsList = AdamantScene(identifier: "DogeTransactionsViewController") { r in
            let c = DogeTransactionsViewController(nibName: "TransactionsListViewControllerBase", bundle: nil)
            c.dialogService = r.resolve(DialogService.self)
            c.router = r.resolve(Router.self)
            return c
        }
        
        /// Lisk transaction details
        static let transactionDetails = AdamantScene(identifier: "TransactionDetailsViewControllerBase") { r in
            let c = DogeTransactionDetailsViewController()
            c.dialogService = r.resolve(DialogService.self)
            return c
        }
    }
}
