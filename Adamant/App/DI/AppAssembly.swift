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
import FilesStorageKit
import FilesPickerKit

struct AppAssembly: Assembly {
    func assemble(container: Container) {
        // MARK: - Standalone services
        // MARK: AdamantCore
        container.register(AdamantCore.self) { _ in NativeAdamantCore() }.inObjectScope(.container)
        
        // MARK: FilesStorageProtocol
        container.register(FilesStorageProtocol.self) { _ in FilesStorageKit() }.inObjectScope(.container)
        
        container.register(FilesPickerProtocol.self) { r in
            FilesPickerKit(storageKit: r.resolve(FilesStorageProtocol.self)!)
        }
        
        // MARK: CellFactory
        container.register(CellFactory.self) { _ in AdamantCellFactory() }.inObjectScope(.container)
        
        // MARK: Secured Store
        container.register(SecuredStore.self) { _ in
            KeychainStore(secureStorage: AdamantSecureStorage())
        }.inObjectScope(.container)
        
        // MARK: LocalAuthentication
        container.register(LocalAuthentication.self) { _ in AdamantAuthentication() }.inObjectScope(.container)
        
        // MARK: Reachability
        container.register(ReachabilityMonitor.self) { _ in AdamantReachability() }.inObjectScope(.container)
        
        // MARK: AdamantAvatarService
        container.register(AvatarService.self) { _ in AdamantAvatarService() }.inObjectScope(.container)
        
        // MARK: - Services with dependencies
        // MARK: DialogService
        container.register(DialogService.self) { r in
            AdamantDialogService(
                vibroService: r.resolve(VibroService.self)!,
                notificationsService: r.resolve(NotificationsService.self)!
            )
        }.inObjectScope(.container)
        
        // MARK: Notifications
        container.register(NotificationsService.self) { r in
            AdamantNotificationsService(
                securedStore: r.resolve(SecuredStore.self)!,
                vibroService: r.resolve(VibroService.self)!
            )
        }.initCompleted { (r, c) in    // Weak reference
            Task { @MainActor in
                guard let service = c as? AdamantNotificationsService else { return }
                service.accountService = r.resolve(AccountService.self)
                service.chatsProvider = r.resolve(ChatsProvider.self)
            }
        }.inObjectScope(.container)
        
        // MARK: VisibleWalletsService
        container.register(VisibleWalletsService.self) { r in
            AdamantVisibleWalletsService(
                securedStore: r.resolve(SecuredStore.self)!,
                accountService: r.resolve(AccountService.self)!,
                walletsServiceCompose: r.resolve(WalletServiceCompose.self)!
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
        container.register(VibroService.self) { _ in
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
                apiService: r.resolve(AdamantApiServiceProtocol.self)!,
                adamantCore: r.resolve(AdamantCore.self)!,
                accountService: r.resolve(AccountService.self)!
            )
        }.inObjectScope(.container)
        
        // MARK: NodesStorage
        container.register(NodesStorageProtocol.self) { r in
            NodesStorage(
                securedStore: r.resolve(SecuredStore.self)!,
                nodesMergingService: r.resolve(NodesMergingServiceProtocol.self)!,
                defaultNodes: { [provider = r.resolve(DefaultNodesProvider.self)!] groups in
                    provider.get(groups)
                }
            )
        }.inObjectScope(.container)
        
        // MARK: NodesAdditionalParamsStorage
        container.register(NodesAdditionalParamsStorageProtocol.self) { r in
            NodesAdditionalParamsStorage(securedStore: r.resolve(SecuredStore.self)!)
        }.inObjectScope(.container)
        
        // MARK: ApiCore
        container.register(APICoreProtocol.self) { _ in
            APICore()
        }.inObjectScope(.container)
        
        // MARK: ApiService
        container.register(AdamantApiServiceProtocol.self) { r in
            AdamantApiService(
                healthCheckWrapper: .init(
                    service: .init(apiCore: r.resolve(APICoreProtocol.self)!),
                    nodesStorage: r.resolve(NodesStorageProtocol.self)!,
                    nodesAdditionalParamsStorage: r.resolve(NodesAdditionalParamsStorageProtocol.self)!,
                    isActive: true,
                    params: NodeGroup.adm.blockchainHealthCheckParams,
                    connection: r.resolve(ReachabilityMonitor.self)!.connectionPublisher
                ),
                adamantCore: r.resolve(AdamantCore.self)!
            )
        }.inObjectScope(.container)
        
        // MARK: IPFSApiService
        container.register(IPFSApiService.self) { r in
            IPFSApiService(healthCheckWrapper: .init(
                service: .init(apiCore: r.resolve(APICoreProtocol.self)!),
                nodesStorage: r.resolve(NodesStorageProtocol.self)!,
                nodesAdditionalParamsStorage: r.resolve(NodesAdditionalParamsStorageProtocol.self)!,
                isActive: true,
                params: NodeGroup.ipfs.blockchainHealthCheckParams,
                connection: r.resolve(ReachabilityMonitor.self)!.connectionPublisher
            ))
        }.inObjectScope(.container)
        
        // MARK: FilesNetworkManagerProtocol
        container.register(FilesNetworkManagerProtocol.self) { r in
            FilesNetworkManager(ipfsService: r.resolve(IPFSApiService.self)!)
        }.inObjectScope(.container)
        
        // MARK: BtcApiService
        container.register(BtcApiService.self) { r in
            BtcApiService(api: .init(
                service: .init(apiCore: r.resolve(APICoreProtocol.self)!),
                nodesStorage: r.resolve(NodesStorageProtocol.self)!,
                nodesAdditionalParamsStorage: r.resolve(NodesAdditionalParamsStorageProtocol.self)!,
                isActive: true,
                params: NodeGroup.btc.blockchainHealthCheckParams,
                connection: r.resolve(ReachabilityMonitor.self)!.connectionPublisher
            ))
        }.inObjectScope(.container)
        
        // MARK: DogeApiService
        container.register(DogeApiService.self) { r in
            DogeApiService(api: .init(
                service: .init(apiCore: r.resolve(APICoreProtocol.self)!),
                nodesStorage: r.resolve(NodesStorageProtocol.self)!,
                nodesAdditionalParamsStorage: r.resolve(NodesAdditionalParamsStorageProtocol.self)!,
                isActive: true,
                params: NodeGroup.doge.blockchainHealthCheckParams,
                connection: r.resolve(ReachabilityMonitor.self)!.connectionPublisher
            ))
        }.inObjectScope(.container)
        
        // MARK: DashApiService
        container.register(DashApiService.self) { r in
            DashApiService(api: .init(
                service: .init(apiCore: r.resolve(APICoreProtocol.self)!),
                nodesStorage: r.resolve(NodesStorageProtocol.self)!,
                nodesAdditionalParamsStorage: r.resolve(NodesAdditionalParamsStorageProtocol.self)!,
                isActive: true,
                params: NodeGroup.dash.blockchainHealthCheckParams,
                connection: r.resolve(ReachabilityMonitor.self)!.connectionPublisher
            ))
        }.inObjectScope(.container)
        
        // MARK: LskNodeApiService
        container.register(KlyNodeApiService.self) { r in
            KlyNodeApiService(api: .init(
                service: .init(),
                nodesStorage: r.resolve(NodesStorageProtocol.self)!,
                nodesAdditionalParamsStorage: r.resolve(NodesAdditionalParamsStorageProtocol.self)!,
                isActive: true,
                params: NodeGroup.klyNode.blockchainHealthCheckParams,
                connection: r.resolve(ReachabilityMonitor.self)!.connectionPublisher
            ))
        }.inObjectScope(.container)
        
        // MARK: KlyServiceApiService
        container.register(KlyServiceApiService.self) { r in
            KlyServiceApiService(api: .init(
                service: .init(),
                nodesStorage: r.resolve(NodesStorageProtocol.self)!,
                nodesAdditionalParamsStorage: r.resolve(NodesAdditionalParamsStorageProtocol.self)!,
                isActive: true,
                params: NodeGroup.klyService.blockchainHealthCheckParams,
                connection: r.resolve(ReachabilityMonitor.self)!.connectionPublisher
            ))
        }.inObjectScope(.container)
        
        // MARK: EthApiService
        container.register(EthApiService.self) { r in
            r.resolve(ERC20ApiService.self)!
        }.inObjectScope(.transient)
        
        // MARK: ERC20ApiService
        container.register(ERC20ApiService.self) { r in
            ERC20ApiService(api: .init(
                service: .init(apiCore: r.resolve(APICoreProtocol.self)!),
                nodesStorage: r.resolve(NodesStorageProtocol.self)!,
                nodesAdditionalParamsStorage: r.resolve(NodesAdditionalParamsStorageProtocol.self)!,
                isActive: true,
                params: NodeGroup.eth.blockchainHealthCheckParams,
                connection: r.resolve(ReachabilityMonitor.self)!.connectionPublisher
            ))
        }.inObjectScope(.container)
        
        // MARK: SocketService
        container.register(SocketService.self) { r in
            AdamantSocketService(
                nodesStorage: r.resolve(NodesStorageProtocol.self)!,
                nodesAdditionalParamsStorage: r.resolve(NodesAdditionalParamsStorageProtocol.self)!
            )
        }.inObjectScope(.container)
        
        // MARK: AccountService
        container.register(AccountService.self) { r in
            AdamantAccountService(
                apiService: r.resolve(AdamantApiServiceProtocol.self)!,
                adamantCore: r.resolve(AdamantCore.self)!,
                dialogService: r.resolve(DialogService.self)!,
                securedStore: r.resolve(SecuredStore.self)!,
                walletServiceCompose: r.resolve(WalletServiceCompose.self)!,
                currencyInfoService: r.resolve(InfoServiceProtocol.self)!
            )
        }.inObjectScope(.container).initCompleted { (r, c) in
            Task { @MainActor in
                guard let service = c as? AdamantAccountService else { return }
                service.notificationsService = r.resolve(NotificationsService.self)!
                service.pushNotificationsTokenService = r.resolve(PushNotificationsTokenService.self)!
                service.visibleWalletService = r.resolve(VisibleWalletsService.self)!
            }
        }
        
        // MARK: AddressBookServeice
        container.register(AddressBookService.self) { r in
            AdamantAddressBookService(
                apiService: r.resolve(AdamantApiServiceProtocol.self)!,
                adamantCore: r.resolve(AdamantCore.self)!,
                accountService: r.resolve(AccountService.self)!,
                dialogService: r.resolve(DialogService.self)!
            )
        }.inObjectScope(.container)
        
        // MARK: LanguageStorageProtocol
        container.register(LanguageStorageProtocol.self) { _ in
            LanguageStorageService()
        }.inObjectScope(.container)
        
        // MARK: - Data Providers
        // MARK: CoreData Stack
        container.register(CoreDataStack.self) { _ in
            try! InMemoryCoreDataStack(modelUrl: AdamantResources.coreDataModel)
        }.inObjectScope(.container)
        
        // MARK: Accounts
        container.register(AccountsProvider.self) { r in
            AdamantAccountsProvider(
                stack: r.resolve(CoreDataStack.self)!,
                apiService: r.resolve(AdamantApiServiceProtocol.self)!,
                addressBookService: r.resolve(AddressBookService.self)!
            )
        }.inObjectScope(.container)
        
        // MARK: Transfers
        container.register(TransfersProvider.self) { r in
            AdamantTransfersProvider(
                apiService: r.resolve(AdamantApiServiceProtocol.self)!,
                stack: r.resolve(CoreDataStack.self)!,
                adamantCore: r.resolve(AdamantCore.self)!,
                accountService: r.resolve(AccountService.self)!,
                accountsProvider: r.resolve(AccountsProvider.self)!,
                securedStore: r.resolve(SecuredStore.self)!,
                transactionService: r.resolve(ChatTransactionService.self)!,
                chatsProvider: r.resolve(ChatsProvider.self)!
            )
        }.inObjectScope(.container)
        
        // MARK: ChatFileService
        container.register(ChatFileProtocol.self) { r in
            ChatFileService(
                accountService: r.resolve(AccountService.self)!,
                filesStorage: r.resolve(FilesStorageProtocol.self)!,
                chatsProvider: r.resolve(ChatsProvider.self)!,
                filesNetworkManager: r.resolve(FilesNetworkManagerProtocol.self)!,
                adamantCore: r.resolve(AdamantCore.self)!
            )
        }.inObjectScope(.container)
        
        // MARK: FilesStorageProprietiesService
        container.register(FilesStorageProprietiesProtocol.self) { r in
            FilesStorageProprietiesService(
                securedStore: r.resolve(SecuredStore.self)!
            )
        }.inObjectScope(.container)
        
        // MARK: ReadedHeightService
        container.register(ReadedHeightService.self) { _ in
            ReadedHeightService()
        }.inObjectScope(.container)
        
        // MARK: Chats
        container.register(ChatsProvider.self) { r in
            AdamantChatsProvider(
                accountService: r.resolve(AccountService.self)!,
                apiService: r.resolve(AdamantApiServiceProtocol.self)!,
                socketService: r.resolve(SocketService.self)!,
                stack: r.resolve(CoreDataStack.self)!,
                adamantCore: r.resolve(AdamantCore.self)!,
                accountsProvider: r.resolve(AccountsProvider.self)!,
                transactionService: r.resolve(ChatTransactionService.self)!,
                securedStore: r.resolve(SecuredStore.self)!,
                walletServiceCompose: r.resolve(WalletServiceCompose.self)!,
                readedHeightService: r.resolve(ReadedHeightService.self)!
            )
        }.inObjectScope(.container)
        
        // MARK: Chat Transaction Service
        container.register(ChatTransactionService.self) { r in
            AdamantChatTransactionService(
                adamantCore: r.resolve(AdamantCore.self)!,
                walletServiceCompose: r.resolve(WalletServiceCompose.self)!
            )
        }.inObjectScope(.container)
        
        // MARK: Rich transaction status service
        container.register(TransactionStatusService.self) { r in
            AdamantTransactionStatusService(
                coreDataStack: r.resolve(CoreDataStack.self)!,
                walletServiceCompose: r.resolve(WalletServiceCompose.self)!,
                nodesStorage: r.resolve(NodesStorageProtocol.self)!
            )
        }.inObjectScope(.container)
        
        // MARK: Rich transaction reply service
        container.register(RichTransactionReplyService.self) { r in
            AdamantRichTransactionReplyService(
                coreDataStack: r.resolve(CoreDataStack.self)!,
                apiService: r.resolve(AdamantApiServiceProtocol.self)!,
                adamantCore: r.resolve(AdamantCore.self)!,
                accountService: r.resolve(AccountService.self)!, 
                walletServiceCompose: r.resolve(WalletServiceCompose.self)!
            )
        }.inObjectScope(.container)
        
        // MARK: Rich transaction react service
        container.register(RichTransactionReactService.self) { r in
            AdamantRichTransactionReactService(
                coreDataStack: r.resolve(CoreDataStack.self)!,
                apiService: r.resolve(AdamantApiServiceProtocol.self)!,
                adamantCore: r.resolve(AdamantCore.self)!,
                accountService: r.resolve(AccountService.self)!
            )
        }.inObjectScope(.container)
        
        // MARK: Bitcoin AddressConverterFactory
        container.register(AddressConverterFactory.self) { _ in
            AddressConverterFactory()
        }.inObjectScope(.container)
        
        // MARK: Chat Preservation
        container.register(ChatPreservationProtocol.self) { _ in
            ChatPreservation()
        }.inObjectScope(.container)
        
        // MARK: Wallet Service Compose
        container.register(WalletServiceCompose.self) { r in
            var wallets: [WalletCoreProtocol] = [
                AdmWalletService(),
                BtcWalletService(),
                EthWalletService(),
                KlyWalletService(),
                DogeWalletService(),
                DashWalletService()
            ]
            
            let erc20WalletServices = ERC20Token.supportedTokens.map {
                ERC20WalletService(token: $0)
            }
            
            wallets.append(contentsOf: erc20WalletServices)
            
            return AdamantWalletServiceCompose(
                wallets: wallets,
                coreDataStack: r.resolve(CoreDataStack.self)!
            )
        }.inObjectScope(.container).initCompleted { (_, c) in
            Task { @MainActor in
                guard let service = c as? AdamantWalletServiceCompose else { return }
                for case let wallet as SwinjectDependentService in service.getWallets().map({ $0.core }) {
                    wallet.injectDependencies(from: container)
                }
            }
        }
        
        // MARK: ApiService Compose
        container.register(ApiServiceComposeProtocol.self) {
            ApiServiceCompose(
                btc: $0.resolve(BtcApiService.self)!,
                eth: $0.resolve(EthApiService.self)!,
                klyNode: $0.resolve(KlyNodeApiService.self)!,
                klyService: $0.resolve(KlyServiceApiService.self)!,
                doge: $0.resolve(DogeApiService.self)!,
                dash: $0.resolve(DashApiService.self)!,
                adm: $0.resolve(AdamantApiServiceProtocol.self)!,
                ipfs: $0.resolve(IPFSApiService.self)!,
                infoService: $0.resolve(InfoServiceApiServiceProtocol.self)!
            )
        }.inObjectScope(.transient)
        
        // MARK: NodesMergingService
        container.register(NodesMergingServiceProtocol.self) { _ in
            NodesMergingService()
        }.inObjectScope(.transient)
        
        // MARK: DefaultNodesProvider
        container.register(DefaultNodesProvider.self) { _ in
            DefaultNodesProvider()
        }.inObjectScope(.transient)
    }
}
