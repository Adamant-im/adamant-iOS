//
//  AdmWalletRoutes.swift
//  Adamant
//
//  Created by Anokhov Pavel on 28.08.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

extension AdamantScene.Wallets {
    struct Adamant {
        /// Wallet preview
        static let wallet = AdamantScene(identifier: "AdmWalletViewController") { r in
            let c = AdmWalletViewController(nibName: "WalletViewControllerBase", bundle: nil)
            c.dialogService = r.resolve(DialogService.self)
            c.currencyInfoService = r.resolve(CurrencyInfoService.self)
            c.router = r.resolve(Router.self)
            c.accountService = r.resolve(AccountService.self)
            return c
        }
        
        /// Send money
        static let transfer = AdamantScene(identifier: "AdmTransferViewController") { r in
            AdmTransferViewController(
                accountService: r.resolve(AccountService.self)!,
                accountsProvider: r.resolve(AccountsProvider.self)!,
                dialogService: r.resolve(DialogService.self)!,
                router: r.resolve(Router.self)!,
                currencyInfoService: r.resolve(CurrencyInfoService.self)!
            )
        }
        
        /// Transactions list
        static let transactionsList = AdamantScene(identifier: "AdmTransactionsViewController", factory: { r in
            let c = AdmTransactionsViewController(
                nibName: "TransactionsListViewControllerBase",
                bundle: nil,
                accountService: r.resolve(AccountService.self)!,
                transfersProvider: r.resolve(TransfersProvider.self)!,
                chatsProvider: r.resolve(ChatsProvider.self)!,
                dialogService: r.resolve(DialogService.self)!,
                stack: r.resolve(CoreDataStack.self)!,
                router: r.resolve(Router.self)!,
                addressBookService: r.resolve(AddressBookService.self)!
            )
            return c
        })
        
        /// Adamant transaction details
        static let transactionDetails = AdamantScene(identifier: "TransactionDetailsViewController", factory: { r in
            let c = AdmTransactionDetailsViewController()
            c.accountService = r.resolve(AccountService.self)
            c.dialogService = r.resolve(DialogService.self)
            c.transfersProvider = r.resolve(TransfersProvider.self)
            c.router = r.resolve(Router.self)
            c.currencyInfo = r.resolve(CurrencyInfoService.self)
            return c
        })
        
        /// Buy and Sell options
        static let buyAndSell = AdamantScene(identifier: "BuyAndSell") { r in
            let c = BuyAndSellViewController()
            c.accountService = r.resolve(AccountService.self)
            c.dialogService = r.resolve(DialogService.self)
            return c
        }
        
        private init() {}
    }
}
