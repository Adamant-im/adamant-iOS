//
//  ERC20WalletRouter.swift
//  Adamant
//
//  Created by Anton Boyarkin on 26/06/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import Foundation

extension AdamantScene.Wallets {
    struct ERC20 {
        /// Wallet preview
        static let wallet = AdamantScene(identifier: "ERC20WalletViewController") { r in
            let c = ERC20WalletViewController(nibName: "WalletViewControllerBase", bundle: nil)
            c.dialogService = r.resolve(DialogService.self)
            c.currencyInfoService = r.resolve(CurrencyInfoService.self)
            c.accountService = r.resolve(AccountService.self)
            return c
        }
        
        /// Send money
        static let transfer = AdamantScene(identifier: "ERC20TransferViewController") { r in
            let c = ERC20TransferViewController()
            c.dialogService = r.resolve(DialogService.self)
            c.chatsProvider = r.resolve(ChatsProvider.self)
            c.accountService = r.resolve(AccountService.self)
            c.accountsProvider = r.resolve(AccountsProvider.self)
            c.router = r.resolve(Router.self)
            c.currencyInfoService = r.resolve(CurrencyInfoService.self)
            return c
        }
        
        /// List of Ethereum transactions
        static let transactionsList = AdamantScene(identifier: "ERC20TransactionsViewController") { r in
            let c = ERC20TransactionsViewController(nibName: "TransactionsListViewControllerBase", bundle: nil)
            c.dialogService = r.resolve(DialogService.self)
            c.router = r.resolve(Router.self)
            return c
        }
        
        /// Ethereum transaction details
        static let transactionDetails = AdamantScene(identifier: "TransactionDetailsViewControllerBase") { r in
            let c = ERC20TransactionDetailsViewController()
            c.dialogService = r.resolve(DialogService.self)
            c.currencyInfo = r.resolve(CurrencyInfoService.self)
            return c
        }
    }
}
