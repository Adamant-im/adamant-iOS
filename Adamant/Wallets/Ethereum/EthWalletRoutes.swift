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
			return c
		}
		
		/// Send money
		static let transfer = AdamantScene(identifier: "EthTransferViewController") { r in
			let c = EthTransferViewController()
			c.dialogService = r.resolve(DialogService.self)
			c.chatsProvider = r.resolve(ChatsProvider.self)
			c.accountService = r.resolve(AccountService.self)
            c.accountsProvider = r.resolve(AccountsProvider.self)
            c.router = r.resolve(Router.self)
			return c
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
			let c = EthTransactionDetailsViewController()
			c.dialogService = r.resolve(DialogService.self)
			return c
		}
	}
}
