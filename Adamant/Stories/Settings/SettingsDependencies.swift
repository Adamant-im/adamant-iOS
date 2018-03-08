//
//  SettingsDependencies.swift
//  Adamant
//
//  Created by Anokhov Pavel on 04.02.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Swinject

extension Container {
	func registerAdamantSettingsStory() {
		self.storyboardInitCompleted(SettingsViewController.self) { r, c in
			c.dialogService = r.resolve(DialogService.self)
			c.accountService = r.resolve(AccountService.self)
			c.localAuth = r.resolve(LocalAuthentication.self)
		}
		
		self.storyboardInitCompleted(QRGeneratorViewController.self) { r, c in
			c.dialogService = r.resolve(DialogService.self)
		}
	}
}
