//
//  EthWalletRoutes.swift
//  Adamant
//
//  Created by Anokhov Pavel on 28.08.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

extension AdamantScene.Wallets {
    struct Ethereum {
        /// Wallet preview
        static let wallet = AdamantScene(identifier: "EthWalletViewController") { r in
            let c = EthWalletViewController(nibName: "WalletViewControllerBase", bundle: nil)
            c.dialogService = r.resolve(DialogService.self)
            c.currencyInfoService = r.resolve(CurrencyInfoService.self)
            c.accountService = r.resolve(AccountService.self)
            return c
        }
        
        /// Send money
        static let transfer = AdamantScene(identifier: "EthTransferViewController") { r in
            EthTransferViewController(
                accountService: r.resolve(AccountService.self)!,
                accountsProvider: r.resolve(AccountsProvider.self)!,
                dialogService: r.resolve(DialogService.self)!,
                router: r.resolve(Router.self)!,
                currencyInfoService: r.resolve(CurrencyInfoService.self)!,
                increaseFeeService: r.resolve(IncreaseFeeService.self)!,
                chatsProvider: r.resolve(ChatsProvider.self)!
            )
        }
        
        /// List of Ethereum transactions
        static let transactionsList = AdamantScene(identifier: "EthTransactionsViewController") { r in
            let c = EthTransactionsViewController(nibName: "TransactionsListViewControllerBase", bundle: nil)
            c.dialogService = r.resolve(DialogService.self)
            c.router = r.resolve(Router.self)
            return c
        }
        
        /// Ethereum transaction details
        static let transactionDetails = AdamantScene(identifier: "TransactionDetailsViewControllerBase") { r in
            let c = EthTransactionDetailsViewController(
                dialogService: r.resolve(DialogService.self)!,
                currencyInfo: r.resolve(CurrencyInfoService.self)!
            )
            return c
        }
    }
}
