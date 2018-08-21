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
			return c
		}
		
		static let admTransfer = AdamantScene(identifier: "AdmTransferViewController") { r in
			let c = AdmTransferViewController()
			c.dialogService = r.resolve(DialogService.self)
			return c
		}
		
		private init() {}
	}
}
