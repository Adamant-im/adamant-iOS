//
//  SecretWalletsViewModel.swift
//  Adamant
//
//  Created by Dmitrij Meidus on 28.02.25.
//  Copyright © 2025 Adamant. All rights reserved.
//

import Foundation
import CommonKit
import Combine

@MainActor
final class SecretWalletsViewModel: ObservableObject {
    @Published private(set) var state: SecretWalletsState = .default
    
    private let secretWalletsManager: SecretWalletsManagerProtocol
    private var subscriptions = Set<AnyCancellable>()
    
    init(secretWalletsManager: SecretWalletsManagerProtocol) {
        self.secretWalletsManager = secretWalletsManager
        
        setup()
    }
    
    func pickWallet(at index: Int) {
        if index == 0 {
            secretWalletsManager.activateDefaultWallet()
        } else {
            secretWalletsManager.activateSecretWallet(at: index - 1)
        }
        state.currentActiveIndex = index
    }
    
    func createSecretWallet(password: String) {
        let index = state.wallets.count
        
        secretWalletsManager.createSecretWallet(withPassword: password)
        secretWalletsManager.activateSecretWallet(at: index - 1)
        
        state.wallets.append(WalletItem(name: String.localized("SecretWallets.Menu.Secret\(index)", comment: "Secret wallet menu: regular wallet")))
        self.state.currentActiveIndex = index
    }
}

private extension SecretWalletsViewModel {
    func setup() {
        NotificationCenter.default.notifications(named: .AdamantAccountService.userLoggedOut)
            .sink { [weak self] _ in await self?.removeAllSecretWallets() }
            .store(in: &subscriptions)        
    }
    
    func removeAllSecretWallets() {
        secretWalletsManager.removeAllSecretWallets()
        secretWalletsManager.activateDefaultWallet()
        state.currentActiveIndex = 0
        state.wallets.removeLast(state.wallets.count - 1)
    }
}

// MARK: Naming generation
extension SecretWalletsViewModel {
    func getCurrentWalletName(regularWithEmodji: Bool = true) -> String {
        guard !regularWithEmodji else {
            return state.wallets[state.currentActiveIndex].name
        }
        
        if state.currentActiveIndex == 0 {
            return String.localized("SecretWallets.Menu.Regular.WithoutEmodji", comment: "Regular Wallet")
        } else {
            return state.wallets[state.currentActiveIndex].name
        }
    }
    
    // Used in transferViewControllerBase
    func getNameFor(walletCore: WalletCoreProtocol, regularWithEmodji: Bool = true) -> String {
        let regular = regularWithEmodji ? String.localized("SecretWallets.Menu.Regular", comment: "Regular Wallet") : String.localized("SecretWallets.Menu.Regular.WithoutEmodji", comment: "Regular Wallet")
        var name = state.currentWallet?.name ?? regular
        
        for wallet in secretWalletsManager.getRegularWallet().sorted(includeInvisible: false) where wallet.core.wallet?.address == walletCore.wallet?.address {
            name = regular
            break
        }
        
        return name
    }
    
    // Used in wallet list, transactions list
    func getCurrentWalletEmodji() -> String {
        guard state.currentActiveIndex != 0 else {
            return ""
        }
        return String.localized("SecretWallets.Menu.Secret\(state.currentActiveIndex).Emodji")
    }
    
    // Used in walletViewControllerBase
    func getCurrentWalletCoinName(withCoinName name: String) -> String {
        if state.wallets.count == 1 {
            return String.localizedStringWithFormat(
                String.localized(
                    "SecretWallets.Coin.Regular",
                    comment: "Regular Wallet"
                ),
                name
            )
        }
        
        if state.currentActiveIndex != 0 {
            return String.localizedStringWithFormat(
                String.localized(
                    "SecretWallets.Coin.Secret\(state.currentActiveIndex)",
                    comment: "Secret Wallet"
                ),
                name
            )
        }
        
        return String.localizedStringWithFormat(
            String.localized(
                "SecretWallets.Coin.SecretRegular",
                comment: "Regular Wallet"
            ),
            name
        )
    }
}

private extension SecretWalletsViewModel {
    
}
