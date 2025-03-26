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

private extension SecretWalletsViewModel {
    func setup() {
        self.state.currentActiveIndex = 0
        self.state.wallets.append(WalletItem(name: String.localized("SecretWallets.Menu.Regular", comment: "Secret wallet menu: regular wallet")))
        
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
