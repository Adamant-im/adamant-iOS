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
            c.walletsManager = r.resolve(WalletServicesManager.self)
            return c
        }
        
        /// Send money
        static let transfer = AdamantScene(identifier: "ERC20TransferViewController") { r in
            ERC20TransferViewController(
                chatsProvider: r.resolve(ChatsProvider.self)!,
                accountService: r.resolve(AccountService.self)!,
                accountsProvider: r.resolve(AccountsProvider.self)!,
                dialogService: r.resolve(DialogService.self)!,
                router: r.resolve(Router.self)!,
                currencyInfoService: r.resolve(CurrencyInfoService.self)!,
                increaseFeeService: r.resolve(IncreaseFeeService.self)!
            )
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
            ERC20TransactionDetailsViewController(
                dialogService: r.resolve(DialogService.self)!,
                currencyInfo: r.resolve(CurrencyInfoService.self)!,
                addressBookService: r.resolve(AddressBookService.self)!,
                accountService:  r.resolve(AccountService.self)!
            )
        }
    }
}
