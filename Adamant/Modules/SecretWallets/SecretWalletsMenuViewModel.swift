//
//  SecretWalletsViewModel.swift
//  Adamant
//
//  Created by Dmitrij Meidus on 28.02.25.
//  Copyright © 2025 Adamant. All rights reserved.
//

import CommonKit
import Combine

extension String.adamant {
    enum AddSecretWallet {
        static var title: String {
            .localized(
                "SecretWallets.AddSecretWallet.Title",
                comment: "Secret wallet: add secret wallet title"
            )
        }
        static var description: String {
            .localized(
                "SecretWallets.AddSecretWallet.Description",
                comment: "Secret wallet: add secret wallet description"
            )
        }
        static var passwordPlaceholder: String {
            .localized(
                "SecretWallets.AddSecretWallet.PasswordPlaceholder",
                comment: "Secret wallet: add secret wallet description"
            )
        }
    }
}

@MainActor
final class SecretWalletsMenuViewModel: ObservableObject {
    @Published private(set) var state: SecretWalletsMenuState = .default
    
    private let secretWalletsManager: SecretWalletsManagerProtocol
    private var subscriptions = Set<AnyCancellable>()
    
    nonisolated init(secretWalletsManager: SecretWalletsManagerProtocol) {
        self.secretWalletsManager = secretWalletsManager
        
        Task{ @MainActor in
            setup()
        }
    }
    
    private func setup() {
        self.state.currentActiveIndex = 0
        self.state.wallets.append(WalletItem(name: String.localized("SecretWallets.Menu.Regular", comment: "Secret wallet menu: regular wallet")))
    }
    
    func pickWallet(at index: Int) {
        state.currentActiveIndex = index
        guard index != 0 else { return secretWalletsManager.activateDefaultWallet() }
        secretWalletsManager.activateSecretWallet(at: index - 1)
    }
    
    func createSecretWallet(password: String) {
        let index = state.wallets.count
        
        secretWalletsManager.createSecretWallet(withPassword: password)
        secretWalletsManager.activateSecretWallet(at: index - 1)
        
        state.wallets.append(WalletItem(name: String.localized("SecretWallets.Menu.Secret\(index)", comment: "Secret wallet menu: regular wallet")))
        self.state.currentActiveIndex = index
    }
}
