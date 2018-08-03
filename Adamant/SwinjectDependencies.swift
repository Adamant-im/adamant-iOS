//
//  SwinjectDependencies.swift
//  Adamant
//
//  Created by Anokhov Pavel on 07.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Swinject


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
		self.register(Router.self) { _ in
			let router = SwinjectedRouter()
			router.container = self
			return router
		}.inObjectScope(.container)
		
		// MARK: CellFactory
		self.register(CellFactory.self) { _ in AdamantCellFactory() }.inObjectScope(.container)
		
		// MARK: Secured Store
		self.register(SecuredStore.self) { r in KeychainStore() }.inObjectScope(.container)
		
		// MARK: LocalAuthentication
		self.register(LocalAuthentication.self) { r in AdamantAuthentication() }.inObjectScope(.container)
		
		// MARK: Reachability
		self.register(ReachabilityMonitor.self) { r in AdamantReachability() }.inObjectScope(.container)
		
		
		// MARK: - Services with dependencies
		// MARK: DialogService
		self.register(DialogService.self) { r in
			let service = AdamantDialogService()
			service.router = r.resolve(Router.self)
			return service
		}.inObjectScope(.container)
		
		// MARK: Notifications
		self.register(NotificationsService.self) { r in
			let service = AdamantNotificationsService()
			service.securedStore = r.resolve(SecuredStore.self)
			return service
		}.initCompleted { (r, c) in	// Weak reference
			let service = c as! AdamantNotificationsService
			service.accountService = r.resolve(AccountService.self)
		}.inObjectScope(.container)
		
		// MARK: NodesSource
		self.register(NodesSource.self) { r in
			let service = AdamantNodesSource(defaultNodes: AdamantResources.nodes)
            service.apiService = r.resolve(ApiService.self)!
			service.securedStore = r.resolve(SecuredStore.self)
			return service
        }.inObjectScope(.container)
		
		// MARK: ApiService
        self.register(ApiService.self) { r in
            let service = AdamantApiService()
            service.adamantCore = r.resolve(AdamantCore.self)
            return service
        }.initCompleted { (r, c) in    // Weak reference
            let service = c as! AdamantApiService
            service.nodesSource = r.resolve(NodesSource.self)
        }.inObjectScope(.container)
        
        // MARK: Ethereum ApiService
        self.register(EthApiService.self) { r in
            let service = AdamantEthApiService(apiUrl: AdamantResources.ethServers.first!)
            service.apiService = r.resolve(ApiService.self)!
            service.accountService = r.resolve(AccountService.self)
            return service
        }.inObjectScope(.container)
        
        // MARK: Lisk ApiService
        self.register(LskApiService.self) { r in
            let service = AdamantLskApiService()
            service.apiService = r.resolve(ApiService.self)!
            service.accountService = r.resolve(AccountService.self)
            return service
        }.inObjectScope(.container)
		
		// MARK: AccountService
		self.register(AccountService.self) { r in
			let service = AdamantAccountService()
			service.apiService = r.resolve(ApiService.self)!
			service.adamantCore = r.resolve(AdamantCore.self)!
			service.securedStore = r.resolve(SecuredStore.self)!
			service.notificationsService = r.resolve(NotificationsService.self)!
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
			provider.securedStore = r.resolve(SecuredStore.self)
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
			provider.securedStore = r.resolve(SecuredStore.self)
			return provider
		}.inObjectScope(.container)
	}
	
	func registerAdamantBackgroundFetchServices() {
		// MARK: Secured store
		self.register(SecuredStore.self) { r in KeychainStore() }.inObjectScope(.container)
		
		// MARK: NodesSource
		self.register(NodesSource.self) { r in
			let service = AdamantNodesSource(defaultNodes: AdamantResources.nodes)
			service.securedStore = r.resolve(SecuredStore.self)
			return service
		}.inObjectScope(.container)
		
		// MARK: ApiService
		// No need to init AdamantCore
		self.register(ApiService.self) { r in
			let service = AdamantApiService()
			service.nodesSource = r.resolve(NodesSource.self)
			return service
		}.inObjectScope(.container)
		
		// MARK: Notifications
		self.register(NotificationsService.self) { r in
			let service = AdamantNotificationsService()
			service.securedStore = r.resolve(SecuredStore.self)
			return service
		}.inObjectScope(.container)
		
		// MARK: Fetch Services
		self.register(ChatsProvider.self) { r in
			let provider = AdamantChatsProvider()
			provider.apiService = r.resolve(ApiService.self)
			provider.securedStore = r.resolve(SecuredStore.self)
			return provider
		}.inObjectScope(.container)
		
		self.register(TransfersProvider.self) { r in
			let provider = AdamantTransfersProvider()
			provider.apiService = r.resolve(ApiService.self)
			provider.securedStore = r.resolve(SecuredStore.self)
			return provider
		}.inObjectScope(.container)
	}
}
