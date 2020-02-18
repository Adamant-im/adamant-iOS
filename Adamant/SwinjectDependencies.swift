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
        self.register(AdamantCore.self) { _ in NativeAdamantCore() }.inObjectScope(.container)
        
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
        
        // MARK: AdamantAvatarService
        self.register(AvatarService.self) { r in AdamantAvatarService() }.inObjectScope(.container)
        
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
        }.initCompleted { (r, c) in    // Weak reference
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
        
        // MARK: AccountService
        self.register(AccountService.self) { r in
            let service = AdamantAccountService()
            service.apiService = r.resolve(ApiService.self)!
            service.adamantCore = r.resolve(AdamantCore.self)!
            service.securedStore = r.resolve(SecuredStore.self)!
            service.dialogService = r.resolve(DialogService.self)!
            service.currencyInfoService = r.resolve(CurrencyInfoService.self)!
            
            return service
        }.inObjectScope(.container).initCompleted { (r, c) in
            let service = c as! AdamantAccountService
            service.notificationsService = r.resolve(NotificationsService.self)!
            
            for case let wallet as SwinjectDependentService in service.wallets {
                wallet.injectDependencies(from: self)
            }
        }
        
        // MARK: AddressBookServeice
        self.register(AddressBookService.self) { r in
            let service = AdamantAddressBookService()
            service.apiService = r.resolve(ApiService.self)!
            service.adamantCore = r.resolve(AdamantCore.self)!
            service.accountService = r.resolve(AccountService.self)!
            service.dialogService = r.resolve(DialogService.self)!
            return service
        }.inObjectScope(.container)
        
        // MARK: CurrencyInfoService
        self.register(CurrencyInfoService.self) { r in
            let service = AdamantCurrencyInfoService()
            service.securedStore = r.resolve(SecuredStore.self)
            return service
        }.inObjectScope(.container).initCompleted { (r, c) in
            if let service = c as? AdamantCurrencyInfoService {
                service.accountService = r.resolve(AccountService.self)
            }
        }

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
            provider.addressBookService = r.resolve(AddressBookService.self)
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
            provider.adamantCore = r.resolve(AdamantCore.self)
            return provider
        }.inObjectScope(.container).initCompleted { (r, c) in
            let provider = c as! AdamantTransfersProvider
            provider.chatsProvider = r.resolve(ChatsProvider.self)
        }
        
        // MARK: Chats
        self.register(ChatsProvider.self) { r in
            let provider = AdamantChatsProvider()
            provider.apiService = r.resolve(ApiService.self)
            provider.stack = r.resolve(CoreDataStack.self)
            provider.adamantCore = r.resolve(AdamantCore.self)
            provider.securedStore = r.resolve(SecuredStore.self)
            provider.accountsProvider = r.resolve(AccountsProvider.self)
            
            let accountService = r.resolve(AccountService.self)!
            provider.accountService = accountService
            var richProviders = [String: RichMessageProviderWithStatusCheck]()
            for case let provider as RichMessageProviderWithStatusCheck in accountService.wallets {
                richProviders[type(of: provider).richMessageType] = provider
            }
            provider.richProviders = richProviders
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
