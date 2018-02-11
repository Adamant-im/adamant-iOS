//
//  ChatsDependencies.swift
//  Adamant
//
//  Created by Anokhov Pavel on 12.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Swinject

extension Container {
	func registerAdamantChatsStory() {
		self.storyboardInitCompleted(ChatsListViewController.self) { r, c in
			c.accountService = r.resolve(AccountService.self)
			c.chatsProvider = r.resolve(ChatsProvider.self)
			c.cellFactory = r.resolve(CellFactory.self)
			c.router = r.resolve(Router.self)
		}
		
		self.storyboardInitCompleted(ChatViewController.self) { r, c in
			c.chatsProvider = r.resolve(ChatsProvider.self)
			c.feeCalculator = r.resolve(FeeCalculator.self)
			c.dialogService = r.resolve(DialogService.self)
		}
		
		self.storyboardInitCompleted(NewChatViewController.self) { r, c in
			c.dialogService = r.resolve(DialogService.self)
			c.accountService = r.resolve(AccountService.self)
			c.accountsProvider = r.resolve(AccountsProvider.self)
		}
	}
}
