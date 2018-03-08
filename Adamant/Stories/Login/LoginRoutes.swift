//
//  LoginRoutes.swift
//  Adamant
//
//  Created by Anokhov Pavel on 07.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

extension AdamantStory {
	static let Login = AdamantStory("Login")
}

extension AdamantScene {
	static let Login = AdamantScene(story: .Login, identifier: "LoginViewController")
}
