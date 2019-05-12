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
            c.currencyInfoService = r.resolve(CurrencyInfoService.self)
            return c
        }
        
        /// Send tokens
        static let transfer = AdamantScene(identifier: "DogeTransferViewController") { r in
            let c = DogeTransferViewController()
            c.dialogService = r.resolve(DialogService.self)
            c.chatsProvider = r.resolve(ChatsProvider.self)
            c.accountService = r.resolve(AccountService.self)
            c.accountsProvider = r.resolve(AccountsProvider.self)
            c.router = r.resolve(Router.self)
            return c
        }
        
        /// List of transactions
        static let transactionsList = AdamantScene(identifier: "DogeTransactionsViewController") { r in
            let c = DogeTransactionsViewController(nibName: "TransactionsListViewControllerBase", bundle: nil)
            c.dialogService = r.resolve(DialogService.self)
            c.router = r.resolve(Router.self)
            return c
        }
        
        /// Transaction details
        static let transactionDetails = AdamantScene(identifier: "TransactionDetailsViewControllerBase") { r in
            let c = DogeTransactionDetailsViewController()
            c.dialogService = r.resolve(DialogService.self)
            c.currencyInfo = r.resolve(CurrencyInfoService.self)
            return c
        }
    }
}
