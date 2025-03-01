//
//  SecretWalletsFactory.swift
//  Adamant
//
//  Created by Dmitrij Meidus on 20.02.25.
//  Copyright © 2025 Adamant. All rights reserved.
//

import CommonKit
import Swinject

//TODO: Что на счет заинджектить сюда все зависимости для кошельков и тут инициализировать все кошельки?

struct SecretWalletsFactory {
    private let visibleWalletsService: VisibleWalletsService
    private let accountService: AccountService
    private let securedStore: SecuredStore
    private let container: Container
    
    init(
        visibleWalletsService: VisibleWalletsService,
        accountService: AccountService,
        securedStore: SecuredStore,
        container: Container
    ) {
        self.visibleWalletsService = visibleWalletsService
        self.accountService = accountService
        self.securedStore = securedStore
        self.container = container
    }
    
    func makeSecretWallet(withPassword password: String) -> WalletStoreServiceProtocol {
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
        let walletServiceCompose = AdamantWalletServiceCompose(wallets: wallets)
        Task { @MainActor in
            await injectDependencies(in: walletServiceCompose)
            await initWallets(withPass: password, for: walletServiceCompose)
        }
        let wallet = AdamantWalletStoreService(visibleWalletsService: visibleWalletsService, walletServiceCompose: walletServiceCompose)
        
        return wallet
    }
    
    @MainActor
    private func injectDependencies(in walletService: WalletServiceCompose) async {
        walletService.getWallets().forEach { wallet in
            (wallet.core as? SwinjectDependentService)?.injectDependencies(from: container)
        }
    }
    
    private func initWallets(withPass password: String, for walletService: WalletServiceCompose) async {
        guard let passphrase: String = securedStore.get(StoreKey.accountService.passphrase) else {
            print("No passphrase found")
            return
        }
        
        await withTaskGroup(of: Void.self) { taskGroup in
            for wallet in walletService.getWallets() {
                taskGroup.addTask {
                    _ = try? await wallet.core.initWallet(
                        withPassphrase: passphrase,
                        withPassword: password
                    )
                }
            }
        }
    }
}
