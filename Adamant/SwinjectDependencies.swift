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
	func registerAdamantServices(apiUrl: URL, coreJsUrl core: URL, managedObjectModel model: URL) {
		self.register(AdamantCore.self) { _ in try! JSAdamantCore(coreJsUrl: core) }
		self.register(DialogService.self) { _ in AdamantDialogService() }.inObjectScope(.container)
		self.register(Router.self) { _ in SwinjectedRouter() }.inObjectScope(.container)
		self.register(CellFactory.self) { _ in AdamantCellFactory() }.inObjectScope(.container)
		self.register(ApiService.self) { r in AdamantApiService(apiUrl: apiUrl, adamantCore: r.resolve(AdamantCore.self)!) }.inObjectScope(.container)
		self.register(AccountService.self) { r in AdamantAccountService(apiService: r.resolve(ApiService.self)!,
																	adamantCore: r.resolve(AdamantCore.self)! ,
																	dialogService: r.resolve(DialogService.self)!,
																	router: r.resolve(Router.self)!) }.inObjectScope(.container)
		
		// Fee calculator
		self.register(FeeCalculator.self) { _ in HardFeeCalculator() }
		
		// Chat provider
		self.register(ChatDataProvider.self) { r  in
			let provider = CoreDataChatProvider(managedObjectModel: model)
			provider.accountService = r.resolve(AccountService.self)
			provider.apiService = r.resolve(ApiService.self)
			provider.adamantCore = r.resolve(AdamantCore.self)
			return provider
		}.inObjectScope(.container)
	}
}
