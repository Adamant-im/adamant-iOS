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
			return c
		}
		
		/// Send money
		static let transfer = AdamantScene(identifier: "AdmTransferViewController") { r in
			let c = AdmTransferViewController()
			c.dialogService = r.resolve(DialogService.self)
			c.accountService = r.resolve(AccountService.self)
            c.accountsProvider = r.resolve(AccountsProvider.self)
            c.router = r.resolve(Router.self)
            c.currencyInfoService = r.resolve(CurrencyInfoService.self)
			return c
		}
		
		/// Transactions list
		static let transactionsList = AdamantScene(identifier: "AdmTransactionsViewController", factory: { r in
			let c = AdmTransactionsViewController(nibName: "TransactionsListViewControllerBase", bundle: nil)
			c.accountService = r.resolve(AccountService.self)
			c.transfersProvider = r.resolve(TransfersProvider.self)
			c.dialogService = r.resolve(DialogService.self)
			c.router = r.resolve(Router.self)
			c.stack = r.resolve(CoreDataStack.self)
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
