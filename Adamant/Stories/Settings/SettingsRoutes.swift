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
		static let security = AdamantScene(identifier: "SecurityViewController") { r -> UIViewController in
			let c = SecurityViewController()
			c.accountService = r.resolve(AccountService.self)
			c.dialogService = r.resolve(DialogService.self)
			c.notificationsService = r.resolve(NotificationsService.self)
			c.localAuth = r.resolve(LocalAuthentication.self)
			c.router = r.resolve(Router.self)
			return c
		}
		
		static let settings = AdamantScene(identifier: "SettingsTableViewController", factory: { r in
			let c = SettingsViewController()
			c.dialogService = r.resolve(DialogService.self)
			c.accountService = r.resolve(AccountService.self)
			c.localAuth = r.resolve(LocalAuthentication.self)
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
			c.notificationsService = r.resolve(NotificationsService.self)
			return c
		}
		
		static let about = AdamantScene(identifier: "About") { _ -> UIViewController in
			AboutViewController()
		}
		
		private init() {}
	}
}
