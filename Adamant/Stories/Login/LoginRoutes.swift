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
			let c = LoginViewController()
			c.accountService = r.resolve(AccountService.self)
			c.adamantCore = r.resolve(AdamantCore.self)
			c.dialogService = r.resolve(DialogService.self)
			c.localAuth = r.resolve(LocalAuthentication.self)
            c.router = r.resolve(Router.self)
            c.ethAPiService = r.resolve(EthApiServiceProtocol.self)
            c.lskAPiService = r.resolve(LskApiServiceProtocol.self)
			return c
		})
		
		private init() {}
	}
}
