//
//  LoginDependencies.swift
//  Adamant-ios
//
//  Created by Anokhov Pavel on 07.01.2018.
//  Copyright © 2018 Anokhov Pavel. All rights reserved.
//

import Swinject

extension Container {
	func registerAdamantLoginStory() {
		self.storyboardInitCompleted(LoginViewController.self) { r, c in
			c.loginService = r.resolve(LoginService.self)
		}
	}
}
