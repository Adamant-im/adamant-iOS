//
//  LoginFactory.swift
//  Adamant
//
//  Created by Anokhov Pavel on 07.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import Swinject
import CommonKit

struct LoginFactory {
    let assembler: Assembler
    
    func makeViewController(screenFactory: ScreensFactory) -> LoginViewController {
        LoginViewController(
            accountService: assembler.resolve(AccountService.self)!,
            adamantCore: assembler.resolve(AdamantCore.self)!,
            dialogService: assembler.resolve(DialogService.self)!,
            localAuth: assembler.resolve(LocalAuthentication.self)!,
            screensFactory: screenFactory,
            apiService: assembler.resolve(AdamantApiServiceProtocol.self)!
        )
    }
}
