//
//  SecretWalletsViewModel.swift
//  Adamant
//
//  Created by Dmitrij Meidus on 28.02.25.
//  Copyright © 2025 Adamant. All rights reserved.
//

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
    
    private func setup() {
        self.state.currentActiveIndex = 0
        self.state.wallets.append(WalletItem(name: String.localized("SecretWallets.Menu.Regular", comment: "Secret wallet menu: regular wallet")))
    }
    
    func pickWallet(at index: Int) {
        if index == 0 {
            secretWalletsManager.activateDefaultWallet()
        } else {
            secretWalletsManager.activateSecretWallet(at: index - 1)
        }
        state.currentActiveIndex = index // We must change state after to avoid bugs
    }
    
    func createSecretWallet(password: String) {
        let index = state.wallets.count
        
        secretWalletsManager.createSecretWallet(withPassword: password)
        secretWalletsManager.activateSecretWallet(at: index - 1)
        
        state.wallets.append(WalletItem(name: String.localized("SecretWallets.Menu.Secret\(index)", comment: "Secret wallet menu: regular wallet")))
        self.state.currentActiveIndex = index
    }
}
