//
//  AccountFactory.swift
//  Adamant
//
//  Created by Anokhov Pavel on 07.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Swinject
import UIKit

struct AccountFactory {
    let assembler: Assembler
    
    func makeViewController(screensFactory: ScreensFactory) -> UIViewController {
        let c = AccountViewController()
        c.accountService = assembler.resolve(AccountService.self)
        c.dialogService = assembler.resolve(DialogService.self)
        c.notificationsService = assembler.resolve(NotificationsService.self)
        c.transfersProvider = assembler.resolve(TransfersProvider.self)
        c.localAuth = assembler.resolve(LocalAuthentication.self)
        c.avatarService = assembler.resolve(AvatarService.self)
        c.currencyInfoService = assembler.resolve(CurrencyInfoService.self)
        c.visibleWalletsService = assembler.resolve(VisibleWalletsService.self)
        c.screensFactory = screensFactory
        return c
    }
}
