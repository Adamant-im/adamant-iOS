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
	static let knownContacts = Bundle.main.url(forResource: "knownContacts", withExtension: "json")!
	
	private init() {}
}

// MARK: - Services
extension Container {
	func registerAdamantServices() {
		// MARK: AdamantCore
		self.register(AdamantCore.self) { _ in
			let core = JSAdamantCore()
			core.loadJs(from: AdamantResources.jsCore, queue: DispatchQueue.global(qos: .background)) { result in
				if case .error(let e) = result { fatalError(e.localizedDescription) }
			}
			return core
		}.inObjectScope(.container)
		
		// MARK: DialogService
		self.register(DialogService.self) { _ in AdamantDialogService() }.inObjectScope(.container)
		
		// MARK: Router
		self.register(Router.self) { _ in SwinjectedRouter() }.inObjectScope(.container)
		
		// MARK: CellFactory
		self.register(CellFactory.self) { _ in AdamantCellFactory() }.inObjectScope(.container)
		
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
			service.dialogService = r.resolve(DialogService.self)!
			service.router = r.resolve(Router.self)!
			return service
		}.inObjectScope(.container)
		
		// MARK: ContactsService
		self.register(ContactsService.self) { _ in try! KnownContactsService(contactsJsonUrl: AdamantResources.knownContacts) }.inObjectScope(.container)
		
		// MARK: Fee calculator
		self.register(FeeCalculator.self) { _ in HardFeeCalculator() }.inObjectScope(.container)
		
		// MARK: Chat provider
		self.register(ChatDataProvider.self) { r  in
			let provider = CoreDataChatProvider(managedObjectModel: AdamantResources.coreDataModel)
			provider.accountService = r.resolve(AccountService.self)
			provider.apiService = r.resolve(ApiService.self)
			provider.adamantCore = r.resolve(AdamantCore.self)
			provider.contactsService = r.resolve(ContactsService.self)
			return provider
		}.inObjectScope(.container)
	}
}
