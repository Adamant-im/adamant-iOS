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
        static let lskTransactions = AdamantScene(identifier: "LSKTransactionsViewController", factory: { r in
            let c = LSKTransactionsViewController(nibName: "TransactionsViewController", bundle: nil)
            c.lskApiService = r.resolve(LskApiService.self)
            c.dialogService = r.resolve(DialogService.self)
            c.router = r.resolve(Router.self)
            return c
        })
		
		private init() {}
	}
}
