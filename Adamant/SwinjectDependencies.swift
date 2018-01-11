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
	func registerAdamantServices(apiUrl: URL, coreJsUrl core: URL, utilitiesJsUrl utils: URL) {
		self.register(AdamantCore.self) { _ in try! JSAdamantCore(coreJsUrl: core, utilitiesJsUrl: utils) }
		self.register(DialogService.self) { _ in SwinjectedDialogService() }.inObjectScope(.container)
		self.register(Router.self) { _ in SwinjectedRouter() }.inObjectScope(.container)
		self.register(CellFactory.self) { _ in AdamantCellFactory() }.inObjectScope(.container)
		self.register(ApiService.self) { r in AdamantApiService(apiUrl: apiUrl, adamantCore: r.resolve(AdamantCore.self)!) }.inObjectScope(.container)
		self.register(LoginService.self) { r in AdamantLoginService(apiService: r.resolve(ApiService.self)!,
																	adamantCore: r.resolve(AdamantCore.self)! ,
																	dialogService: r.resolve(DialogService.self)!,
																	router: r.resolve(Router.self)!) }.inObjectScope(.container)
	}
}
