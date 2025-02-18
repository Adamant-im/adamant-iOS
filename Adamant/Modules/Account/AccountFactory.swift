//
//  AccountFactory.swift
//  Adamant
//
//  Created by Anokhov Pavel on 07.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Swinject
import UIKit

@MainActor
struct AccountFactory {
    let assembler: Assembler
    
    func makeViewController(screensFactory: ScreensFactory) -> UIViewController {
        AccountViewController(
            visibleWalletsService: assembler.resolve(VisibleWalletsService.self)!,
            accountService: assembler.resolve(AccountService.self)!,
            dialogService: assembler.resolve(DialogService.self)!,
            screensFactory: screensFactory,
            notificationsService: assembler.resolve(NotificationsService.self)!,
            transfersProvider: assembler.resolve(TransfersProvider.self)!,
            localAuth: assembler.resolve(LocalAuthentication.self)!,
            avatarService: assembler.resolve(AvatarService.self)!,
            currencyInfoService: assembler.resolve(InfoServiceProtocol.self)!,
            languageService: assembler.resolve(LanguageStorageProtocol.self)!,
            walletServiceCompose: assembler.resolve(WalletServiceCompose.self)!,
            apiServiceCompose: assembler.resolve(ApiServiceComposeProtocol.self)!
        )
    }
}
