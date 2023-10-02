//
//  AppAssembly.swift
//  Adamant
//
//  Created by Anokhov Pavel on 07.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Swinject
import BitcoinKit
import CommonKit

struct AppAssembly: Assembly {
    func assemble(container: Container) {
        // MARK: - Standalone services
        // MARK: AdamantCore
        container.register(AdamantCore.self) { _ in NativeAdamantCore() }.inObjectScope(.container)
        
        // MARK: CellFactory
        container.register(CellFactory.self) { _ in AdamantCellFactory() }.inObjectScope(.container)
        
        // MARK: Secured Store
        container.register(SecuredStore.self) { _ in KeychainStore() }.inObjectScope(.container)
        
        // MARK: LocalAuthentication
        container.register(LocalAuthentication.self) { _ in AdamantAuthentication() }.inObjectScope(.container)
        
        // MARK: Reachability
        container.register(ReachabilityMonitor.self) { _ in AdamantReachability() }.inObjectScope(.container)
        
        // MARK: AdamantAvatarService
        container.register(AvatarService.self) { _ in AdamantAvatarService() }.inObjectScope(.container)
        
        // MARK: - Services with dependencies
        // MARK: DialogService
        container.register(DialogService.self) { r in
            AdamantDialogService(vibroService: r.resolve(VibroService.self)!)
        }.inObjectScope(.container)
        
        // MARK: Notifications
        container.register(NotificationsService.self) { r in
            AdamantNotificationsService(securedStore: r.resolve(SecuredStore.self)!)
        }.initCompleted { (r, c) in    // Weak reference
            Task { @MainActor in
                guard let service = c as? AdamantNotificationsService else { return }
                service.accountService = r.resolve(AccountService.self)
            }
        }.inObjectScope(.container)
        
        // MARK: VisibleWalletsService
        container.register(VisibleWalletsService.self) { r in
            AdamantVisibleWalletsService(
                securedStore: r.resolve(SecuredStore.self)!,
                accountService: r.resolve(AccountService.self)!
            )
        }.inObjectScope(.container)
        
        // MARK: IncreaseFeeService
        container.register(IncreaseFeeService.self) { r in
            AdamantIncreaseFeeService(
                securedStore: r.resolve(SecuredStore.self)!
            )
        }.inObjectScope(.container)
        
        // MARK: EmojiService
        container.register(EmojiService.self) { r in
            AdamantEmojiService(
                securedStore: r.resolve(SecuredStore.self)!
            )
        }.inObjectScope(.container)
        
        // MARK: VibroService
        container.register(VibroService.self) { r in
            AdamantVibroService()
        }.inObjectScope(.container)
        
        // MARK: CrashlysticsService
        container.register(CrashlyticsService.self) { r in
            AdamantCrashlyticsService(
                securedStore: r.resolve(SecuredStore.self)!
            )
        }.inObjectScope(.container)
        
        // MARK: PushNotificationsTokenService
        container.register(PushNotificationsTokenService.self) { r in
            AdamantPushNotificationsTokenService(
                securedStore: r.resolve(SecuredStore.self)!,
                apiService: r.resolve(ApiService.self)!,
                adamantCore: r.resolve(AdamantCore.self)!,
                accountService: r.resolve(AccountService.self)!
            )
        }.inObjectScope(.container)
        
        // MARK: NodesSource
        container.register(NodesSource.self) { r in
            AdamantNodesSource(
                apiService: r.resolve(ApiService.self)!,
                healthCheckService: r.resolve(HealthCheckService.self)!,
                securedStore: r.resolve(SecuredStore.self)!,
                defaultNodesGetter: { AdamantResources.nodes }
            )
        }.inObjectScope(.container)
        
        // MARK: ApiService
        container.register(ApiService.self) { r in
            AdamantApiService(adamantCore: r.resolve(AdamantCore.self)!)
        }.initCompleted { (r, c) in    // Weak reference
            Task { @MainActor in
                guard let service = c as? AdamantApiService else { return }
                await service.setupWeakDeps(nodesSource: r.resolve(NodesSource.self)!)
            }
        }.inObjectScope(.container)
        
        // MARK: HealthCheckService
        container.register(HealthCheckService.self) { r in
            AdamantHealthCheckService(apiService: r.resolve(ApiService.self)!)
        }.inObjectScope(.container)
        
        // MARK: SocketService
        container.register(SocketService.self) { _ in
            AdamantSocketService()
        }.initCompleted { (r, c) in    // Weak reference
            guard let service = c as? AdamantSocketService else { return }
            service.nodesSource = r.resolve(NodesSource.self)
        }.inObjectScope(.container)
        
        // MARK: AccountService
        container.register(AccountService.self) { r in
            AdamantAccountService(
                apiService: r.resolve(ApiService.self)!,
                adamantCore: r.resolve(AdamantCore.self)!,
                dialogService: r.resolve(DialogService.self)!,
                securedStore: r.resolve(SecuredStore.self)!
            )
        }.inObjectScope(.container).initCompleted { (r, c) in
            Task { @MainActor in
                guard let service = c as? AdamantAccountService else { return }
                service.notificationsService = r.resolve(NotificationsService.self)!
                service.pushNotificationsTokenService = r.resolve(PushNotificationsTokenService.self)!
                service.currencyInfoService = r.resolve(CurrencyInfoService.self)!
                service.visibleWalletService = r.resolve(VisibleWalletsService.self)!
                for case let wallet as SwinjectDependentService in service.wallets {
                    wallet.injectDependencies(from: container)
                }
            }
        }
        
        // MARK: AddressBookServeice
        container.register(AddressBookService.self) { r in
            AdamantAddressBookService(
                apiService: r.resolve(ApiService.self)!,
                adamantCore: r.resolve(AdamantCore.self)!,
                accountService: r.resolve(AccountService.self)!,
                dialogService: r.resolve(DialogService.self)!
            )
        }.inObjectScope(.container)
        
        // MARK: CurrencyInfoService
        container.register(CurrencyInfoService.self) { r in
            AdamantCurrencyInfoService(securedStore: r.resolve(SecuredStore.self)!)
        }.inObjectScope(.container).initCompleted { (r, c) in
            guard let service = c as? AdamantCurrencyInfoService else { return }
            service.accountService = r.resolve(AccountService.self)
        }
        
        // MARK: - Data Providers
        // MARK: CoreData Stack
        container.register(CoreDataStack.self) { _ in
            try! InMemoryCoreDataStack(modelUrl: AdamantResources.coreDataModel)
        }.inObjectScope(.container)
        
        // MARK: Accounts
        container.register(AccountsProvider.self) { r in
            AdamantAccountsProvider(
                stack: r.resolve(CoreDataStack.self)!,
                apiService: r.resolve(ApiService.self)!,
                addressBookService: r.resolve(AddressBookService.self)!
            )
        }.inObjectScope(.container)
        
        // MARK: Transfers
        container.register(TransfersProvider.self) { r in
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
        container.register(ChatsProvider.self) { r in
            AdamantChatsProvider(
                accountService: r.resolve(AccountService.self)!,
                apiService: r.resolve(ApiService.self)!,
                socketService: r.resolve(SocketService.self)!,
                stack: r.resolve(CoreDataStack.self)!,
                adamantCore: r.resolve(AdamantCore.self)!,
                accountsProvider: r.resolve(AccountsProvider.self)!,
                transactionService: r.resolve(ChatTransactionService.self)!,
                securedStore: r.resolve(SecuredStore.self)!
            )
        }.inObjectScope(.container)
        
        // MARK: Chat Transaction Service
        container.register(ChatTransactionService.self) { r in
            AdamantChatTransactionService(
                adamantCore: r.resolve(AdamantCore.self)!,
                accountService: r.resolve(AccountService.self)!
            )
        }.inObjectScope(.container)
        
        // MARK: Rich transaction status service
        container.register(RichTransactionStatusService.self) { r in
            let accountService = r.resolve(AccountService.self)!
            
            let richProviders = accountService.wallets
                .compactMap { $0 as? RichMessageProviderWithStatusCheck }
                .map { ($0.dynamicRichMessageType, $0) }
            
            return AdamantRichTransactionStatusService(
                coreDataStack: r.resolve(CoreDataStack.self)!,
                richProviders: Dictionary(uniqueKeysWithValues: richProviders)
            )
        }.inObjectScope(.container)
        
        // MARK: Rich transaction reply service
        container.register(RichTransactionReplyService.self) { r in
            AdamantRichTransactionReplyService(
                coreDataStack: r.resolve(CoreDataStack.self)!,
                apiService: r.resolve(ApiService.self)!,
                adamantCore: r.resolve(AdamantCore.self)!,
                accountService: r.resolve(AccountService.self)!
            )
        }.inObjectScope(.container)
        
        // MARK: Rich transaction react service
        container.register(RichTransactionReactService.self) { r in
            AdamantRichTransactionReactService(
                coreDataStack: r.resolve(CoreDataStack.self)!,
                apiService: r.resolve(ApiService.self)!,
                adamantCore: r.resolve(AdamantCore.self)!,
                accountService: r.resolve(AccountService.self)!
            )
        }.inObjectScope(.container)
        
        // MARK: Bitcoin AddressConverterFactory
        container.register(AddressConverterFactory.self) { _ in
            AddressConverterFactory()
        }.inObjectScope(.container)
    }
}
