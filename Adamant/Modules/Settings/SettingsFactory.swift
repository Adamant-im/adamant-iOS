//
//  SettingsFactory.swift
//  Adamant
//
//  Created by Anokhov Pavel on 01.02.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import CommonKit
import Swinject

struct SettingsFactory {
    let assembler: Assembler
    
    func makeSecurityVC(screensFactory: ScreensFactory) -> UIViewController {
        let c = SecurityViewController()
        c.accountService = assembler.resolve(AccountService.self)
        c.dialogService = assembler.resolve(DialogService.self)
        c.notificationsService = assembler.resolve(NotificationsService.self)
        c.localAuth = assembler.resolve(LocalAuthentication.self)
        c.screensFactory = screensFactory
        return c
    }
    
    func makeQRGeneratorVC() -> UIViewController {
        let c = QRGeneratorViewController()
        c.dialogService = assembler.resolve(DialogService.self)
        return c
    }
    
    func makePKGeneratorVC() -> UIViewController {
        PKGeneratorViewController(
            dialogService: assembler.resolve(DialogService.self)!,
            walletServiceCompose: assembler.resolve(WalletServiceCompose.self)!
        )
    }
    
    func makeAboutVC(screensFactory: ScreensFactory) -> UIViewController {
        AboutViewController(
            accountService: assembler.resolve(AccountService.self)!,
            accountsProvider: assembler.resolve(AccountsProvider.self)!,
            dialogService: assembler.resolve(DialogService.self)!,
            screensFactory: screensFactory,
            vibroService: assembler.resolve(VibroService.self)!
        )
    }
    
    func makeVisibleWalletsVC() -> UIViewController {
        VisibleWalletsViewController(
            visibleWalletsService: assembler.resolve(VisibleWalletsService.self)!,
            accountService: assembler.resolve(AccountService.self)!
        )
    }
}
