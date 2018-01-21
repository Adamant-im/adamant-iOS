//
//  ChatsRoutes.swift
//  Adamant-ios
//
//  Created by Anokhov Pavel on 12.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

extension AdamantStory {
	static let Chats = AdamantStory("Chats")
}

extension AdamantScene {
	static let ChatsList = AdamantScene(story: .Chats, identifier: "ChatsListViewController")
	static let Chat = AdamantScene(story: .Chats, identifier: "ChatViewController")
	static let NewChat = AdamantScene(story: .Chats, identifier: "NewChatViewController")
}
