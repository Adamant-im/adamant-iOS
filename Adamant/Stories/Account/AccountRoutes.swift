//
//  AccountRoutes.swift
//  Adamant
//
//  Created by Anokhov Pavel on 07.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

extension AdamantScene {
    enum Account {
        static let account = AdamantScene(identifier: "AccountViewController") { r in
            let c = AccountViewController()
            c.accountService = r.resolve(AccountService.self)
            c.dialogService = r.resolve(DialogService.self)
            c.router = r.resolve(Router.self)
            c.notificationsService = r.resolve(NotificationsService.self)
            c.transfersProvider = r.resolve(TransfersProvider.self)
            c.localAuth = r.resolve(LocalAuthentication.self)
            c.avatarService = r.resolve(AvatarService.self)
            c.currencyInfoService = r.resolve(CurrencyInfoService.self)
            c.visibleWalletsService = r.resolve(VisibleWalletsService.self)
            c.walletsManager = r.resolve(WalletServicesManager.self)
            return c
        }
    }
}
