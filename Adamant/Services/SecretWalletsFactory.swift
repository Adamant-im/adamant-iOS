//
//  SecretWalletsFactory.swift
//  Adamant
//
//  Created by Dmitrij Meidus on 20.02.25.
//  Copyright © 2025 Adamant. All rights reserved.
//

import CommonKit

struct SecretWalletsFactory {
    private let visibleWalletsService: VisibleWalletsService
    private let accountService: AccountService
    private let SecureStore: SecureStore

    init(
        visibleWalletsService: VisibleWalletsService,
        accountService: AccountService,
        SecureStore: SecureStore
    ) {
        self.visibleWalletsService = visibleWalletsService
        self.accountService = accountService
        self.SecureStore = SecureStore
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
        Task.detached(priority: .userInitiated) {
            await initWallets(withPass: password, for: walletServiceCompose)
        }
        let wallet = AdamantWalletStoreService(visibleWalletsService: visibleWalletsService, walletServiceCompose: walletServiceCompose)

        return wallet
    }

    private func initWallets(withPass password: String, for walletService: WalletServiceCompose) async {
        guard let passphrase: String = SecureStore.get(StoreKey.accountService.passphrase) else {
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
