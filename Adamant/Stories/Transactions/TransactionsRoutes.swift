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
			let c = TransactionsViewController(nibName: "TransactionsViewController", bundle: nil)
			c.transfersProvider = r.resolve(TransfersProvider.self)
			c.router = r.resolve(Router.self)
			return c
		})
		
		static let transactionDetails = AdamantScene(identifier: "TransactionDetailsViewController", factory: { r in
			let c = TransactionDetailsViewController(nibName: "TransactionDetailsViewController", bundle: nil)
			c.dialogService = r.resolve(DialogService.self)
			return c
		})
	}
}
