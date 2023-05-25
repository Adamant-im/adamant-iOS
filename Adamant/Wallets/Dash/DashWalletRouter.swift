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
            c.accountService = r.resolve(AccountService.self)
            return c
        }
        
        /// Send tokens
        static let transfer = AdamantScene(identifier: "DashTransferViewController") { r in
            DashTransferViewController(
                chatsProvider: r.resolve(ChatsProvider.self)!,
                accountService: r.resolve(AccountService.self)!,
                accountsProvider: r.resolve(AccountsProvider.self)!,
                dialogService: r.resolve(DialogService.self)!,
                router: r.resolve(Router.self)!,
                currencyInfoService: r.resolve(CurrencyInfoService.self)!
            )
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
            DashTransactionDetailsViewController(
                dialogService: r.resolve(DialogService.self)!,
                currencyInfo: r.resolve(CurrencyInfoService.self)!,
                addressBookService: r.resolve(AddressBookService.self)!,
                accountService:  r.resolve(AccountService.self)!
            )
        }
    }
}
