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
        self.register(SecuredStore.self) { _ in KeychainStore() }.inObjectScope(.container)
        
        // MARK: LocalAuthentication
        self.register(LocalAuthentication.self) { _ in AdamantAuthentication() }.inObjectScope(.container)
        
        // MARK: Reachability
        self.register(ReachabilityMonitor.self) { _ in AdamantReachability() }.inObjectScope(.container)
        
        // MARK: AdamantAvatarService
        self.register(AvatarService.self) { _ in AdamantAvatarService() }.inObjectScope(.container)
        
        // MARK: - Services with dependencies
        // MARK: DialogService
        self.register(DialogService.self) { r in
            AdamantDialogService(router: r.resolve(Router.self)!)
        }.inObjectScope(.container)
        
        // MARK: Notifications
        self.register(NotificationsService.self) { r in
            AdamantNotificationsService(securedStore: r.resolve(SecuredStore.self)!)
        }.initCompleted { (r, c) in    // Weak reference
            guard let service = c as? AdamantNotificationsService else { return }
            service.accountService = r.resolve(AccountService.self)
        }.inObjectScope(.container)
        
        // MARK: PushNotificationsTokenService
        self.register(PushNotificationsTokenService.self) { r in
            AdamantPushNotificationsTokenService(
                securedStore: r.resolve(SecuredStore.self)!,
                apiService: r.resolve(ApiService.self)!,
                adamantCore: r.resolve(AdamantCore.self)!,
                accountService: r.resolve(AccountService.self)!
            )
        }.inObjectScope(.container)
        
        // MARK: NodesSource
        self.register(NodesSource.self) { r in
            AdamantNodesSource(
                apiService: r.resolve(ApiService.self)!,
                healthCheckService: r.resolve(HealthCheckService.self)!,
                securedStore: r.resolve(SecuredStore.self)!,
                defaultNodesGetter: { AdamantResources.nodes }
            )
        }.inObjectScope(.container)
        
        // MARK: ApiService
        self.register(ApiService.self) { r in
            AdamantApiService(adamantCore: r.resolve(AdamantCore.self)!)
        }.initCompleted { (r, c) in    // Weak reference
            guard let service = c as? AdamantApiService else { return }
            service.nodesSource = r.resolve(NodesSource.self)
        }.inObjectScope(.container)
        
        // MARK: HealthCheckService
        self.register(HealthCheckService.self) { r in
            AdamantHealthCheckService(apiService: r.resolve(ApiService.self)!)
        }.inObjectScope(.container)
        
        // MARK: SocketService
        self.register(SocketService.self) { _ in
            AdamantSocketService()
        }.initCompleted { (r, c) in    // Weak reference
            guard let service = c as? AdamantSocketService else { return }
            service.nodesSource = r.resolve(NodesSource.self)
        }.inObjectScope(.container)
        
        // MARK: AccountService
        self.register(AccountService.self) { r in
            AdamantAccountService(
                apiService: r.resolve(ApiService.self)!,
                adamantCore: r.resolve(AdamantCore.self)!,
                dialogService: r.resolve(DialogService.self)!,
                securedStore: r.resolve(SecuredStore.self)!
            )
        }.inObjectScope(.container).initCompleted { (r, c) in
            guard let service = c as? AdamantAccountService else { return }
            service.notificationsService = r.resolve(NotificationsService.self)!
            service.pushNotificationsTokenService = r.resolve(PushNotificationsTokenService.self)!
            service.currencyInfoService = r.resolve(CurrencyInfoService.self)!
            
            for case let wallet as SwinjectDependentService in service.wallets {
                wallet.injectDependencies(from: self)
            }
        }
        
        // MARK: AddressBookServeice
        self.register(AddressBookService.self) { r in
            AdamantAddressBookService(
                apiService: r.resolve(ApiService.self)!,
                adamantCore: r.resolve(AdamantCore.self)!,
                accountService: r.resolve(AccountService.self)!,
                dialogService: r.resolve(DialogService.self)!
            )
        }.inObjectScope(.container)
        
        // MARK: CurrencyInfoService
        self.register(CurrencyInfoService.self) { r in
            AdamantCurrencyInfoService(securedStore: r.resolve(SecuredStore.self)!)
        }.inObjectScope(.container).initCompleted { (r, c) in
            guard let service = c as? AdamantCurrencyInfoService else { return }
            service.accountService = r.resolve(AccountService.self)
        }
        
        // MARK: - Data Providers
        // MARK: CoreData Stack
        self.register(CoreDataStack.self) { _ in
            try! InMemoryCoreDataStack(modelUrl: AdamantResources.coreDataModel)
        }.inObjectScope(.container)
        
        // MARK: Accounts
        self.register(AccountsProvider.self) { r in
            AdamantAccountsProvider(
                stack: r.resolve(CoreDataStack.self)!,
                apiService: r.resolve(ApiService.self)!,
                addressBookService: r.resolve(AddressBookService.self)!
            )
        }.inObjectScope(.container)
        
        // MARK: Transfers
        self.register(TransfersProvider.self) { r in
            AdamantTransfersProvider(
                apiService: r.resolve(ApiService.self)!,
                stack: r.resolve(CoreDataStack.self)!,
                adamantCore: r.resolve(AdamantCore.self)!,
                accountService: r.resolve(AccountService.self)!,
                accountsProvider: r.resolve(AccountsProvider.self)!,
                securedStore: r.resolve(SecuredStore.self)!,
                transactionService: r.resolve(ChatTransactionService.self)!
            )
        }.inObjectScope(.container).initCompleted { (r, c) in
            guard let service = c as? AdamantTransfersProvider else { return }
            service.chatsProvider = r.resolve(ChatsProvider.self)
        }
        
        // MARK: Chats
        self.register(ChatsProvider.self) { r in
            AdamantChatsProvider(
                accountService: r.resolve(AccountService.self)!,
                apiService: r.resolve(ApiService.self)!,
                socketService: r.resolve(SocketService.self)!,
                stack: r.resolve(CoreDataStack.self)!,
                adamantCore: r.resolve(AdamantCore.self)!,
                accountsProvider: r.resolve(AccountsProvider.self)!,
                transactionService: r.resolve(ChatTransactionService.self)!,
                securedStore: r.resolve(SecuredStore.self)!,
                richTransactionStatusService: r.resolve(RichTransactionStatusService.self)!
            )
        }.inObjectScope(.container)
        
        // MARK: Chat Transaction Service
        self.register(ChatTransactionService.self) { r in
            AdamantChatTransactionService(
                adamantCore: r.resolve(AdamantCore.self)!,
                accountService: r.resolve(AccountService.self)!
            )
        }.inObjectScope(.container)
        
        // MARK: Chat screen factory
        self.register(ChatFactory.self) { r in
            ChatFactory(
                chatsProvider: r.resolve(ChatsProvider.self)!,
                dialogService: r.resolve(DialogService.self)!,
                transferProvider: r.resolve(TransfersProvider.self)!,
                accountService: r.resolve(AccountService.self)!,
                addressBookService: r.resolve(AddressBookService.self)!,
                router: r.resolve(Router.self)!
            )
        }
        
        // MARK: Rich transaction status service
        self.register(RichTransactionStatusService.self) { r in
            let accountService = r.resolve(AccountService.self)!
            
            let richProviders = accountService.wallets
                .compactMap { $0 as? RichMessageProviderWithStatusCheck }
                .map { ($0.dynamicRichMessageType, $0) }
            
            return AdamantRichTransactionStatusService(
                richProviders: Dictionary(uniqueKeysWithValues: richProviders)
            )
        }
    }
}
