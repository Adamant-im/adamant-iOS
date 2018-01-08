//
//  AccountRoutes.swift
//  Adamant-ios
//
//  Created by Anokhov Pavel on 07.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

extension AdamantStory {
	static let Account = AdamantStory("Account")
}

extension AdamantScene {
	static let AccountDetails = AdamantScene(story: .Account, identifier: "AccountViewController")
}
