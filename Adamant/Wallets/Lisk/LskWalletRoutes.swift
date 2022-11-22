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
            c.currencyInfoService = r.resolve(CurrencyInfoService.self)
            c.accountService = r.resolve(AccountService.self)
            return c
        }
        
        /// Send LSK tokens
        static let transfer = AdamantScene(identifier: "LskTransferViewController") { r in
            let c = LskTransferViewController()
            c.dialogService = r.resolve(DialogService.self)
            c.chatsProvider = r.resolve(ChatsProvider.self)
            c.accountService = r.resolve(AccountService.self)
            c.accountsProvider = r.resolve(AccountsProvider.self)
            c.router = r.resolve(Router.self)
            c.currencyInfoService = r.resolve(CurrencyInfoService.self)
            return c
        }
        
        /// List of Lisk transactions
        static let transactionsList = AdamantScene(identifier: "LskTransactionsViewController") { r in
            let c = LskTransactionsViewController(nibName: "TransactionsListViewControllerBase", bundle: nil)
            c.dialogService = r.resolve(DialogService.self)
            c.router = r.resolve(Router.self)
            return c
        }
        
        /// Lisk transaction details
        static let transactionDetails = AdamantScene(identifier: "TransactionDetailsViewControllerBase") { r in
            let c = LskTransactionDetailsViewController()
            c.dialogService = r.resolve(DialogService.self)
            c.currencyInfo = r.resolve(CurrencyInfoService.self)
            return c
        }
    }
}
