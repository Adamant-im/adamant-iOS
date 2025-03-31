//
//  AdamantSecretWalletsManager.swift
//  Adamant
//
//  Created by Dmitrij Meidus on 19.02.25.
//  Copyright © 2025 Adamant. All rights reserved.
//

import Foundation
import Swinject
import CommonKit

private extension AdamantSecretWalletsManager {
    struct State: SecretWalletsManagerStateProtocol {
        var currentWallet: WalletStoreServiceProtocol
        var regularWallet: WalletStoreServiceProtocol
        var secretWallets: [WalletStoreServiceProtocol] = []
    }
}

final class AdamantSecretWalletsManager: SecretWalletsManagerProtocol {
    private let secretWalletsFactory: SecretWalletsFactory
    
    @Atomic private var state: SecretWalletsManagerStateProtocol
    var statePublisher = ObservableSender<SecretWalletsManagerStateProtocol>()
    
    var wallets: [WalletStoreServiceProtocol] { [state.regularWallet] + state.secretWallets }
    
    init(
        walletsStoreService: WalletStoreServiceProtocol,
        secretWalletsFactory: SecretWalletsFactory
    ) {
        self.state = State(
            currentWallet: walletsStoreService,
            regularWallet: walletsStoreService
        )
        self.secretWalletsFactory = secretWalletsFactory
    }
    
    // MARK: - Manage state
    func createSecretWallet(withPassword password: String) {
        let wallet = secretWalletsFactory.makeSecretWallet(withPassword: password)
        _state.mutate {
            $0.secretWallets.append(wallet)
        }
    }
    
    func removeSecretWallet(at index: Int) -> WalletStoreServiceProtocol? {
        guard state.secretWallets.indices.contains(index) else { return nil }
        return _state.mutate {
            return $0.secretWallets.remove(at: index)
        }
    }
    
    func getCurrentWallet() -> WalletStoreServiceProtocol {
        state.currentWallet
    }
    
    func getRegularWallet() -> WalletStoreServiceProtocol {
        state.regularWallet
    }
    
    func getSecretWallets() -> [WalletStoreServiceProtocol] {
        state.secretWallets
    }
    
    func activateSecretWallet(at index: Int) {
        guard index < state.secretWallets.count else { return }
        _state.mutate {
            $0.currentWallet = state.secretWallets[index]
        }
        statePublisher.send(state)
    }
    
    func activateDefaultWallet() {
        _state.mutate {
            $0.currentWallet = state.regularWallet
        }
        statePublisher.send(state)
    }
}
