//
//  SwinjectDependencies.swift
//  Adamant-ios
//
//  Created by Anokhov Pavel on 07.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Swinject
import SwinjectStoryboard

// MARK: Services
extension Container {
	func registerAdamantServices(coreJsUrl core: URL, utilitiesJsUrl utils: URL) {
		self.register(AdamantCore.self) { _ in try! JSAdamantCore(coreJsUrl: core, utilitiesJsUrl: utils) }
		self.register(DialogService.self) { _ in SwinjectedDialogService() }.inObjectScope(.container)
		self.register(Router.self) { _ in SwinjectedRouter() }.inObjectScope(.container)
		self.register(CellFactory.self) { _ in AdamantCellFactory() }.inObjectScope(.container)
		self.register(ApiService.self) { r in AdamantApiService(adamantCore: r.resolve(AdamantCore.self)!) }.inObjectScope(.container)
		self.register(LoginService.self) { r in
			let api = r.resolve(ApiService.self)!
			let dialog = r.resolve(DialogService.self)!
			return AdamantLoginService(apiService: api, dialogService: dialog)
		}.inObjectScope(.container)
	}
}
