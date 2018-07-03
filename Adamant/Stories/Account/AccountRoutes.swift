//
//  AccountRoutes.swift
//  Adamant
//
//  Created by Anokhov Pavel on 07.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

extension AdamantScene {
	struct Account {
		static let account = AdamantScene(identifier: "AccountViewController") { r in
			let c = AccountViewController()
			c.accountService = r.resolve(AccountService.self)
			c.dialogService = r.resolve(DialogService.self)
			c.router = r.resolve(Router.self)
			return c
		}
		
		static let wallet = AdamantScene(identifier: "WalletViewController") { r in
			let c = WalletViewController()
			c.accountService = r.resolve(AccountService.self)
			c.dialogService = r.resolve(DialogService.self)
			c.router = r.resolve(Router.self)
			return c
		}
		
		static let transfer = AdamantScene(identifier: "TransferViewController") { r in
			let c = TransferViewController()
			c.apiService = r.resolve(ApiService.self)
			c.accountService = r.resolve(AccountService.self)
			c.dialogService = r.resolve(DialogService.self)
			return c
		}
		
		private init() {}
	}
}
