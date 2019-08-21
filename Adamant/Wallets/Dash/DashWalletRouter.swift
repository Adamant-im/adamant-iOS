//
//  DashWalletRouter.swift
//  Adamant
//
//  Created by Anton Boyarkin on 25/04/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import Foundation

extension AdamantScene.Wallets {
    struct Dash {
        /// Wallet preview
        static let wallet = AdamantScene(identifier: "DashWalletViewController") { r in
            let c = DashWalletViewController(nibName: "WalletViewControllerBase", bundle: nil)
            c.dialogService = r.resolve(DialogService.self)
            c.currencyInfoService = r.resolve(CurrencyInfoService.self)
            return c
        }
        
        /// Send tokens
        static let transfer = AdamantScene(identifier: "DashTransferViewController") { r in
            let c = DashTransferViewController()
            c.dialogService = r.resolve(DialogService.self)
            c.chatsProvider = r.resolve(ChatsProvider.self)
            c.accountService = r.resolve(AccountService.self)
            c.accountsProvider = r.resolve(AccountsProvider.self)
            c.router = r.resolve(Router.self)
            c.currencyInfoService = r.resolve(CurrencyInfoService.self)
            return c
        }
        
        /// List of transactions
        static let transactionsList = AdamantScene(identifier: "DashTransactionsViewController") { r in
            let c = DashTransactionsViewController(nibName: "TransactionsListViewControllerBase", bundle: nil)
            c.dialogService = r.resolve(DialogService.self)
            c.router = r.resolve(Router.self)
            return c
        }
        
        /// Transaction details
        static let transactionDetails = AdamantScene(identifier: "TransactionDetailsViewControllerBase") { r in
            let c = DashTransactionDetailsViewController()
            c.dialogService = r.resolve(DialogService.self)
            c.currencyInfo = r.resolve(CurrencyInfoService.self)
            return c
        }
    }
}
