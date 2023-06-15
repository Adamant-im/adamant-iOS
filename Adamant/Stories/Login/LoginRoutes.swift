//
//  LoginRoutes.swift
//  Adamant
//
//  Created by Anokhov Pavel on 07.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

extension AdamantScene {
    struct Login {
        static let login = AdamantScene(identifier: "LoginViewController", factory: { r in
            LoginViewController(
                accountService:  r.resolve(AccountService.self)!,
                adamantCore:  r.resolve(AdamantCore.self)!,
                dialogService: r.resolve(DialogService.self)!,
                localAuth: r.resolve(LocalAuthentication.self)!,
                router: r.resolve(Router.self)!,
                apiService: r.resolve(ApiService.self)!,
                crashliticsService: r.resolve(CrashlyticsService.self)!
            )
        })
        
        private init() {}
    }
}
