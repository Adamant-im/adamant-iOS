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
		self.storyboardInitCompleted(SettingsTableViewController.self) { r, c in
			c.dialogService = r.resolve(DialogService.self)
		}
	}
}
