//
//  SettingsRoutes.swift
//  Adamant
//
//  Created by Anokhov Pavel on 01.02.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit

extension AdamantScene {
	struct Settings {
		static let settings = AdamantScene(identifier: "SettingsTableViewController", factory: { r in
			let c = SettingsViewController()
			c.dialogService = r.resolve(DialogService.self)
			c.accountService = r.resolve(AccountService.self)
			c.localAuth = r.resolve(LocalAuthentication.self)
			c.notificationsService = r.resolve(NotificationsService.self)
			c.router = r.resolve(Router.self)
			return c
		})
		
		static let qRGenerator = AdamantScene(identifier: "QRGeneratorViewController", factory: { r in
			let c = QRGeneratorViewController()
			c.dialogService = r.resolve(DialogService.self)
			return c
		})
		
		static let notifications = AdamantScene(identifier: "NotificationsViewController") { r -> UIViewController in
			let c = NotificationsViewController()
			return c
		}
		
		private init() {}
	}
}
