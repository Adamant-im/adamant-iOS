//
//  SecretWalletsViewModel.swift
//  Adamant
//
//  Created by Dmitrij Meidus on 28.02.25.
//  Copyright © 2025 Adamant. All rights reserved.
//

import CommonKit
import Combine

extension SecretWalletsAlertService {
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
            self.state.currentActiveIndex = secretWalletsManager.currentWalletIndex
            self.state.wallets.append(WalletItem(name: "Regular"))
            for index in 0...secretWalletsManager.getSecretWallets().count - 1 where index > 0 {
                state.wallets.append(WalletItem(name: "Secret \(index)"))
            }
        }
        
        func pickWallet(at index: Int) {
            state.currentActiveIndex = index
            secretWalletsManager.activateWallet(at: index)
        }
        
        func createSecretWallet(password: String) {
            let index = state.wallets.count
            
            secretWalletsManager.createSecretWallet(withPassword: password)
            secretWalletsManager.activateWallet(at: index )
            
            self.state.wallets.append(WalletItem(name: "Secret \(index)"))
            self.state.currentActiveIndex = index
        }
        
        func removeSecretWallet(at index: Int) {
            _ = secretWalletsManager.removeSecretWallet(at: index)
            state.wallets.remove(at: index)
            if index == state.currentActiveIndex {
                state.currentActiveIndex = 0
                secretWalletsManager.activateWallet(at: 0)
            }
        }
    }
}
