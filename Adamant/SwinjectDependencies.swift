//
//  SwinjectDependencies.swift
//  Adamant
//
//  Created by Anokhov Pavel on 07.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Swinject
import BitcoinKit
import CommonKit

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
        
        // MARK: Wallet services
        self.register(WalletServicesManager.self) { _ in
            AdamantWalletServicesManager()
        }.inObjectScope(.container)
        
        // MARK: - Services with dependencies
        // MARK: DialogService
        self.register(DialogService.self) { r in
            AdamantDialogService(router: r.resolve(Router.self)!)
        }.inObjectScope(.container)
        
        // MARK: Notifications
        self.register(NotificationsService.self) { r in
            AdamantNotificationsService(securedStore: r.resolve(SecuredStore.self)!)
        }.initCompleted { (r, c) in    // Weak reference
            Task { @MainActor in
                guard let service = c as? AdamantNotificationsService else { return }
                service.accountService = r.resolve(AccountService.self)
            }
        }.inObjectScope(.container)
        
        // MARK: VisibleWalletsService
        self.register(VisibleWalletsService.self) { r in
            AdamantVisibleWalletsService(
                securedStore: r.resolve(SecuredStore.self)!,
                walletsManager: r.resolve(WalletServicesManager.self)!
            )
        }.inObjectScope(.container)
        
        // MARK: IncreaseFeeService
        self.register(IncreaseFeeService.self) { r in
            AdamantIncreaseFeeService(
                securedStore: r.resolve(SecuredStore.self)!
            )
        }.inObjectScope(.container)
        
        // MARK: CrashlysticsService
        self.register(CrashlyticsService.self) { r in
            AdamantCrashlyticsService(
                securedStore: r.resolve(SecuredStore.self)!
            )
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
                securedStore: r.resolve(SecuredStore.self)!,
                reachabilityMonitor: r.resolve(ReachabilityMonitor.self)!,
                walletsManager: r.resolve(WalletServicesManager.self)!,
                visibleWalletService: r.resolve(VisibleWalletsService.self)!
            )
        }.inObjectScope(.container).initCompleted { (r, c) in
            Task { @MainActor in
                guard let service = c as? AdamantAccountService else { return }
                
                await service.setupWeakDeps(
                    notificationsService: r.resolve(NotificationsService.self),
                    currencyInfoService: r.resolve(CurrencyInfoService.self),
                    pushNotificationsTokenService: r.resolve(PushNotificationsTokenService.self)
                )
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
            AdamantCurrencyInfoService(
                securedStore: r.resolve(SecuredStore.self)!,
                walletsManager: r.resolve(WalletServicesManager.self)!
            )
        }.inObjectScope(.container)
        
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
                transactionService: r.resolve(ChatTransactionService.self)!,
                chatsProvider: r.resolve(ChatsProvider.self)!
            )
        }.inObjectScope(.container)
        
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
                walletsManager: r.resolve(WalletServicesManager.self)!
            )
        }.inObjectScope(.container)
        
        // MARK: Chat Transaction Service
        self.register(ChatTransactionService.self) { r in
            AdamantChatTransactionService(
                adamantCore: r.resolve(AdamantCore.self)!,
                walletsManager: r.resolve(WalletServicesManager.self)!
            )
        }.inObjectScope(.container)
        
        // MARK: Chat screen factory
        self.register(ChatFactory.self) { r in
            ChatFactory(
                chatsProvider: r.resolve(ChatsProvider.self)!,
                dialogService: r.resolve(DialogService.self)!,
                transferProvider: r.resolve(TransfersProvider.self)!,
                accountService: r.resolve(AccountService.self)!,
                accountProvider: r.resolve(AccountsProvider.self)!,
                richTransactionStatusService: r.resolve(RichTransactionStatusService.self)!,
                addressBookService: r.resolve(AddressBookService.self)!,
                visibleWalletService: r.resolve(VisibleWalletsService.self)!,
                walletsManager: r.resolve(WalletServicesManager.self)!,
                router: r.resolve(Router.self)!
            )
        }.inObjectScope(.container)
        
        // MARK: Contribute screen factory
        self.register(ContributeFactory.self) { r in
            ContributeFactory(crashliticsService: r.resolve(CrashlyticsService.self)!)
        }.inObjectScope(.container)
        
        // MARK: Rich transaction status service
        self.register(RichTransactionStatusService.self) { r in
            let accountService = r.resolve(AccountService.self)!
            
            return AdamantRichTransactionStatusService(
                coreDataStack: r.resolve(CoreDataStack.self)!,
                walletsManager: r.resolve(WalletServicesManager.self)!
            )
        }.inObjectScope(.container)
        
        // MARK: Rich transaction reply service
        self.register(RichTransactionReplyService.self) { r in
            AdamantRichTransactionReplyService(
                coreDataStack: r.resolve(CoreDataStack.self)!,
                apiService: r.resolve(ApiService.self)!,
                adamantCore: r.resolve(AdamantCore.self)!,
                accountService: r.resolve(AccountService.self)!,
                walletsManager: r.resolve(WalletServicesManager.self)!
            )
        }.inObjectScope(.container)
        
        // MARK: Bitcoin AddressConverterFactory
        self.register(AddressConverterFactory.self) { r in
            AddressConverterFactory()
        }.inObjectScope(.container)
    }
}
