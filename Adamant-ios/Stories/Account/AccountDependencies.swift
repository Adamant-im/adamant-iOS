//
//  AccountDependencies.swift
//  Adamant-ios
//
//  Created by Anokhov Pavel on 07.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Swinject

extension Container {
	func registerAdamantAccountStory() {
		self.storyboardInitCompleted(AccountViewController.self) { r, c in
			c.loginService = r.resolve(LoginService.self)
		}
	}
}
