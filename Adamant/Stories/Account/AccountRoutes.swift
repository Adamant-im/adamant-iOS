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
			c.notificationsService = r.resolve(NotificationsService.self)
			c.transfersProvider = r.resolve(TransfersProvider.self)
            c.ethApiService = r.resolve(EthApiServiceProtocol.self)
            c.lskApiService = r.resolve(LskApiServiceProtocol.self)
			return c
		}
		
		static let transfer = AdamantScene(identifier: "TransferViewController") { r in
			let c = TransferViewController()
			c.apiService = r.resolve(ApiService.self)
			c.accountService = r.resolve(AccountService.self)
			c.dialogService = r.resolve(DialogService.self)
            c.ethApiService = r.resolve(EthApiServiceProtocol.self)
            c.lskApiService = r.resolve(LskApiServiceProtocol.self)
			return c
		}
		
		private init() {}
	}
}
