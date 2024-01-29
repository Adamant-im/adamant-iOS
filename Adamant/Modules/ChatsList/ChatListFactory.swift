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
        ChatListViewController(
            accountService: assembler.resolve(AccountService.self)!,
            chatsProvider: assembler.resolve(ChatsProvider.self)!,
            transfersProvider: assembler.resolve(TransfersProvider.self)!,
            screensFactory: screensFactory,
            notificationsService: assembler.resolve(NotificationsService.self)!,
            dialogService: assembler.resolve(DialogService.self)!,
            addressBook: assembler.resolve(AddressBookService.self)!,
            avatarService: assembler.resolve(AvatarService.self)!,
            walletServiceCompose: assembler.resolve(WalletServiceCompose.self)!
        )
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
        ComplexTransferViewController(
            visibleWalletsService: assembler.resolve(VisibleWalletsService.self)!,
            addressBookService: assembler.resolve(AddressBookService.self)!,
            screensFactory: screensFactory,
            walletServiceCompose: assembler.resolve(WalletServiceCompose.self)!
        )
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
