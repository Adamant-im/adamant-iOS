//
//  TransactionsRoutes.swift
//  Adamant
//
//  Created by Anokhov Pavel on 17.03.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

extension AdamantScene {
	struct Transactions {
		static let transactions = AdamantScene(identifier: "TransactionsViewController", factory: { r in
			let c = ADMTransactionsViewController(nibName: "TransactionsViewController", bundle: nil)
			c.accountService = r.resolve(AccountService.self)
			c.transfersProvider = r.resolve(TransfersProvider.self)
			c.dialogService = r.resolve(DialogService.self)
			c.router = r.resolve(Router.self)
			c.stack = r.resolve(CoreDataStack.self)
			return c
		})
		
		static let transactionDetails = AdamantScene(identifier: "TransactionDetailsViewController", factory: { r in
			let c = TransactionDetailsViewController(nibName: "TransactionDetailsViewController", bundle: nil)
            c.accountService = r.resolve(AccountService.self)
			c.dialogService = r.resolve(DialogService.self)
            c.transfersProvider = r.resolve(TransfersProvider.self)
            c.router = r.resolve(Router.self)
			return c
		})
        
        static let ethTransactions = AdamantScene(identifier: "TransactionsViewController", factory: { r in
            let c = ETHTransactionsViewController(nibName: "TransactionsViewController", bundle: nil)
            c.ethApiService = r.resolve(EthApiServiceProtocol.self)
            c.dialogService = r.resolve(DialogService.self)
            c.router = r.resolve(Router.self)
            return c
        })
        
        static let ethTransactionDetails = AdamantScene(identifier: "TransactionDetailsViewController", factory: { r in
            let c = ETHTransactionDetailsViewController()
            c.dialogService = r.resolve(DialogService.self)
            c.ethApiService = r.resolve(EthApiServiceProtocol.self)
            return c
        })
		
		private init() {}
	}
}
