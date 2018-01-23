//
//  LoginDependencies.swift
//  Adamant-ios
//
//  Created by Anokhov Pavel on 07.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Swinject

extension Container {
	func registerAdamantLoginStory() {
		self.storyboardInitCompleted(LoginViewController.self) { r, c in
			c.accountService = r.resolve(AccountService.self)
			c.apiService = r.resolve(ApiService.self)
			c.adamantCore = r.resolve(AdamantCore.self)
		}
	}
}
