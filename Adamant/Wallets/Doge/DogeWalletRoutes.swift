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
            c.walletsManager = r.resolve(WalletServicesManager.self)
            return c
        }
        
        /// Send tokens
        static let transfer = AdamantScene(identifier: "DogeTransferViewController") { r in
            DogeTransferViewController(
                chatsProvider: r.resolve(ChatsProvider.self)!,
                accountService: r.resolve(AccountService.self)!,
                accountsProvider: r.resolve(AccountsProvider.self)!,
                dialogService: r.resolve(DialogService.self)!,
                router: r.resolve(Router.self)!,
                currencyInfoService: r.resolve(CurrencyInfoService.self)!,
                increaseFeeService: r.resolve(IncreaseFeeService.self)!
            )
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
            DogeTransactionDetailsViewController(
                dialogService: r.resolve(DialogService.self)!,
                currencyInfo: r.resolve(CurrencyInfoService.self)!,
                addressBookService: r.resolve(AddressBookService.self)!,
                accountService:  r.resolve(AccountService.self)!
            )
        }
    }
}
