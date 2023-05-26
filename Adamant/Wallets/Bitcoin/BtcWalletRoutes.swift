//
//  BtcWalletRoutes.swift
//  Adamant
//
//  Created by Anton Boyarkin on 14/01/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import Foundation

extension AdamantScene.Wallets {
    struct Bitcoin {
        /// Wallet preview
        static let wallet = AdamantScene(identifier: "BtcWalletViewController") { r in
            let c = BtcWalletViewController(nibName: "WalletViewControllerBase", bundle: nil)
            c.dialogService = r.resolve(DialogService.self)
            c.currencyInfoService = r.resolve(CurrencyInfoService.self)
            c.accountService = r.resolve(AccountService.self)
            return c
        }

        /// Send BTC tokens
        static let transfer = AdamantScene(identifier: "BtcTransferViewController") { r in
            BtcTransferViewController(
                chatsProvider: r.resolve(ChatsProvider.self)!,
                accountService: r.resolve(AccountService.self)!,
                accountsProvider: r.resolve(AccountsProvider.self)!,
                dialogService: r.resolve(DialogService.self)!,
                router: r.resolve(Router.self)!,
                currencyInfoService: r.resolve(CurrencyInfoService.self)!
            )
        }

        /// List of BTC transactions
        static let transactionsList = AdamantScene(identifier: "BtcTransactionsViewController") { r in
            let c = BtcTransactionsViewController(nibName: "TransactionsListViewControllerBase", bundle: nil)
            c.dialogService = r.resolve(DialogService.self)
            c.router = r.resolve(Router.self)
            c.addressBook = r.resolve(AddressBookService.self)
            return c
        }

        /// BTC transaction details
        static let transactionDetails = AdamantScene(identifier: "TransactionDetailsViewControllerBase") { r in
            BtcTransactionDetailsViewController(
                dialogService: r.resolve(DialogService.self)!,
                currencyInfo: r.resolve(CurrencyInfoService.self)!,
                addressBookService: r.resolve(AddressBookService.self)!,
                accountService:  r.resolve(AccountService.self)!
            )
        }
    }
}
