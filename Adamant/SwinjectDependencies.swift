//
//  SwinjectDependencies.swift
//  Adamant
//
//  Created by Anokhov Pavel on 07.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Swinject
import SwinjectStoryboard

// MARK: - Resources
private struct AdamantResources {
	// Storyboard
	static let jsCore = Bundle.main.url(forResource: "adamant-core", withExtension: "js")!
	static let api = URL(string: "https://endless.adamant.im")!
	static let coreDataModel = Bundle.main.url(forResource: "ChatModels", withExtension: "momd")!
	
	private init() {}
}

// MARK: - Services
extension Container {
	func registerAdamantServices() {
		// MARK: - Standalone services
		// MARK: AdamantCore
		self.register(AdamantCore.self) { _ in
			let core = JSAdamantCore()
			core.loadJs(from: AdamantResources.jsCore, queue: DispatchQueue.global(qos: .background)) { result in
				if case .error(let e) = result { fatalError(e.localizedDescription) }
			}
			return core
		}.inObjectScope(.container)
		
		// MARK: Router
		self.register(Router.self) { _ in SwinjectedRouter() }.inObjectScope(.container)
		
		// MARK: CellFactory
		self.register(CellFactory.self) { _ in AdamantCellFactory() }.inObjectScope(.container)
		
		// MARK: DialogService
		self.register(DialogService.self) { r in AdamantDialogService() }.inObjectScope(.container)
		
		
		// MARK: - Services with dependencies
		// MARK: ApiService
		self.register(ApiService.self) { r in
			let service = AdamantApiService(apiUrl: AdamantResources.api)
			service.adamantCore = r.resolve(AdamantCore.self)!
			return service
		}.inObjectScope(.container)
		
		// MARK: AccountService
		self.register(AccountService.self) { r in
			let service = AdamantAccountService()
			service.apiService = r.resolve(ApiService.self)!
			service.adamantCore = r.resolve(AdamantCore.self)!
			return service
		}.inObjectScope(.container)
		
		
		// MARK: - Data Providers
		// MARK: CoreData Stack
		self.register(CoreDataStack.self) { _ in
			try! InMemoryCoreDataStack(modelUrl: AdamantResources.coreDataModel)
		}.inObjectScope(.container)
		
		// MARK: Accounts
		self.register(AccountsProvider.self) { r in
			let provider = AdamantAccountsProvider()
			provider.stack = r.resolve(CoreDataStack.self)
			provider.apiService = r.resolve(ApiService.self)
			return provider
		}.inObjectScope(.container)
		
		// MARK: Transfers
		self.register(TransfersProvider.self) { r in
			let provider = AdamantTransfersProvider()
			provider.apiService = r.resolve(ApiService.self)
			provider.stack = r.resolve(CoreDataStack.self)
			provider.accountService = r.resolve(AccountService.self)
			provider.accountsProvider = r.resolve(AccountsProvider.self)
			return provider
		}.inObjectScope(.container)
		
		// MARK: Chats
		self.register(ChatsProvider.self) { r in
			let provider = AdamantChatsProvider()
			provider.accountService = r.resolve(AccountService.self)
			provider.apiService = r.resolve(ApiService.self)
			provider.stack = r.resolve(CoreDataStack.self)
			provider.adamantCore = r.resolve(AdamantCore.self)
			provider.accountsProvider = r.resolve(AccountsProvider.self)
			return provider
		}.inObjectScope(.container)
	}
}
