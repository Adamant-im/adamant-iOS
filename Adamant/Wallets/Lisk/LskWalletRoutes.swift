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
            c.walletsManager = r.resolve(WalletServicesManager.self)!
            return c
        }
        
        /// Send LSK tokens
        static let transfer = AdamantScene(identifier: "LskTransferViewController") { r in
            LskTransferViewController(
                chatsProvider: r.resolve(ChatsProvider.self)!,
                accountService: r.resolve(AccountService.self)!,
                accountsProvider: r.resolve(AccountsProvider.self)!,
                dialogService: r.resolve(DialogService.self)!,
                router: r.resolve(Router.self)!,
                currencyInfoService: r.resolve(CurrencyInfoService.self)!,
                increaseFeeService: r.resolve(IncreaseFeeService.self)!
            )
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
            LskTransactionDetailsViewController(
                dialogService: r.resolve(DialogService.self)!,
                currencyInfo: r.resolve(CurrencyInfoService.self)!,
                addressBookService: r.resolve(AddressBookService.self)!,
                accountService:  r.resolve(AccountService.self)!
            )
        }
    }
}
