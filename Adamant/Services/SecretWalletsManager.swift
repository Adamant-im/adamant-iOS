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
        state.secretWallets.append(wallet)
    }
    
    func removeSecretWallet(at index: Int) -> WalletStoreServiceProtocol? {
        guard state.secretWallets.indices.contains(index) else { return nil }
        return state.secretWallets.remove(at: index)
    }
    
    func getCurrentWallet() -> WalletStoreServiceProtocol {
        state.currentWallet
    }
    
    func getSecretWallets() -> [WalletStoreServiceProtocol] {
        state.secretWallets
    }
    
    func activateSecretWallet(at index: Int) {
        guard index < state.secretWallets.count else { return }
        state.currentWallet = state.secretWallets[index]
        statePublisher.send(state)
    }
    
    func activateDefaultWallet() {
        state.currentWallet = state.regularWallet
        statePublisher.send(state)
    }
}
