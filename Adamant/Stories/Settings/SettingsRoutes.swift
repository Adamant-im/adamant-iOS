//
//  SettingsRoutes.swift
//  Adamant
//
//  Created by Anokhov Pavel on 01.02.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

extension AdamantStory {
	static let Settings = AdamantStory("Settings")
}

extension AdamantScene {
	static let SettingsPage = AdamantScene(story: .Settings, identifier: "SettingsTableViewController")
	static let QRGenerator = AdamantScene(story: .Settings, identifier: "QRGeneratorViewController")
}
