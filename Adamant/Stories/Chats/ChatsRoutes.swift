//
//  ChatsRoutes.swift
//  Adamant
//
//  Created by Anokhov Pavel on 12.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit

extension AdamantScene {
	struct Chats {
		static let chatList = AdamantScene(identifier: "ChatListViewController", factory: { r in
			let c = ChatListViewController(nibName: "ChatListViewController", bundle: nil)
			c.accountService = r.resolve(AccountService.self)
			c.chatsProvider = r.resolve(ChatsProvider.self)
			c.transfersProvider = r.resolve(TransfersProvider.self)
			c.router = r.resolve(Router.self)
			c.notificationsService = r.resolve(NotificationsService.self)
			c.dialogService = r.resolve(DialogService.self)
			c.addressBook = r.resolve(AddressBookService.self)
            c.avatarService = r.resolve(AvatarService.self)
            
            // MARK: RichMessage handlers
            // Transfer handlers from accountService' wallet services
            if let accountService = r.resolve(AccountService.self) {
                for case let provider as RichMessageProvider in accountService.wallets {
                    c.richMessageProviders[type(of: provider).richMessageType] = provider
                }
            }
            
			return c
		})
		
		static let chat = AdamantScene(identifier: "ChatViewController", factory: { r in
			let c = ChatViewController()
			c.chatsProvider = r.resolve(ChatsProvider.self)
            c.transfersProvider = r.resolve(TransfersProvider.self)
			c.dialogService = r.resolve(DialogService.self)
			c.router = r.resolve(Router.self)
            c.addressBookService = r.resolve(AddressBookService.self)
            c.stack = r.resolve(CoreDataStack.self)
            c.securedStore = r.resolve(SecuredStore.self)
            
            // MARK: RichMessage handlers
            // Transfer handlers from accountService' wallet services
            if let accountService = r.resolve(AccountService.self) {
                for case let provider as RichMessageProvider in accountService.wallets {
                    c.richMessageProviders[type(of: provider).richMessageType] = provider
                }
            }
			
            return c
		})
		
		static let newChat = AdamantScene(identifier: "NewChatViewController", factory: { r in
			let c = NewChatViewController()
			c.dialogService = r.resolve(DialogService.self)
			c.accountService = r.resolve(AccountService.self)
			c.accountsProvider = r.resolve(AccountsProvider.self)
			c.router = r.resolve(Router.self)
			
			let navigator = UINavigationController(rootViewController: c)
            navigator.modalPresentationStyle = .overFullScreen
			return navigator
		})
		
		static let complexTransfer = AdamantScene(identifier: "ComplexTransferViewController", factory: { r in
			let c = ComplexTransferViewController()
			c.accountService = r.resolve(AccountService.self)
			return c
		})
        
        static let searchResults = AdamantScene(identifier: "SearchResultsViewController", factory: { r in
            let c = SearchResultsViewController(nibName: "SearchResultsViewController", bundle: nil)
            c.router = r.resolve(Router.self)
            c.avatarService = r.resolve(AvatarService.self)
            return c
        })
		
		private init() {}
	}
}
