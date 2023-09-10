//
//  ChatListFactory.swift
//  Adamant
//
//  Created by Anokhov Pavel on 12.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import Swinject

struct ChatListFactory {
    let assembler: Assembler
    
    func makeChatListVC(screensFactory: ScreensFactory) -> UIViewController {
        let c = ChatListViewController(nibName: "ChatListViewController", bundle: nil)
        c.accountService = assembler.resolve(AccountService.self)
        c.chatsProvider = assembler.resolve(ChatsProvider.self)
        c.transfersProvider = assembler.resolve(TransfersProvider.self)
        c.screensFactory = screensFactory
        c.notificationsService = assembler.resolve(NotificationsService.self)
        c.dialogService = assembler.resolve(DialogService.self)
        c.addressBook = assembler.resolve(AddressBookService.self)
        c.avatarService = assembler.resolve(AvatarService.self)
        
        // MARK: RichMessage handlers
        // Transfer handlers from accountService' wallet services
        if let accountService = assembler.resolve(AccountService.self) {
            for case let provider as RichMessageProvider in accountService.wallets {
                c.richMessageProviders[provider.dynamicRichMessageType] = provider
            }
        }
        
        return c
    }
    
    func makeNewChatVC(screensFactory: ScreensFactory) -> NewChatViewController {
        let c = NewChatViewController()
        c.dialogService = assembler.resolve(DialogService.self)
        c.accountService = assembler.resolve(AccountService.self)
        c.accountsProvider = assembler.resolve(AccountsProvider.self)
        c.screensFactory = screensFactory
        return c
    }
    
    func makeComplexTransferVC(screensFactory: ScreensFactory) -> UIViewController {
        let c = ComplexTransferViewController()
        c.accountService = assembler.resolve(AccountService.self)
        c.visibleWalletsService = assembler.resolve(VisibleWalletsService.self)
        c.addressBookService = assembler.resolve(AddressBookService.self)
        c.screensFactory = screensFactory
        return c
    }
    
    func makeSearchResultsViewController(screensFactory: ScreensFactory) -> SearchResultsViewController {
        SearchResultsViewController(
            screensFactory: screensFactory,
            avatarService: assembler.resolve(AvatarService.self)!,
            addressBookService: assembler.resolve(AddressBookService.self)!,
            accountsProvider: assembler.resolve(AccountsProvider.self)!
        )
    }
}
