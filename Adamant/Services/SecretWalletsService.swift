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

extension AdamantSecretWalletsManager {
    struct State: SecretWalletsManagerStateProtocol {
        var currentWallet: WalletStoreServiceProtocol
        let defaultWallet: WalletStoreServiceProtocol
        var secretWallets: [WalletStoreServiceProtocol] = []
    }
}

final class AdamantSecretWalletsManager: SecretWalletsManagerProtocol {
    private let secretWalletsFactory: SecretWalletsFactory
    private let lock = NSLock()
    
    init(
        walletsStoreService: WalletStoreServiceProtocol,
        secretWalletsFactory: SecretWalletsFactory
    ) {
        self.state = State(
            currentWallet: walletsStoreService,
            defaultWallet: walletsStoreService
        )
        self.secretWalletsFactory = secretWalletsFactory
    }
    
    @ObservableValue private var state: SecretWalletsManagerStateProtocol
    var statePublisher: AnyObservable<SecretWalletsManagerStateProtocol> {
        $state.eraseToAnyPublisher()
    }
    
    // MARK: - Manage state
    func createSecretWallet(withPassword password: String) {
        let wallet = secretWalletsFactory.makeSecretWallet(withPassword: password)
        lock.lock()
        defer { lock.unlock() }
        state.secretWallets.append(wallet)
    }
    
    func removeSecretWallet(at index: Int) -> WalletStoreServiceProtocol? {
        lock.lock()
        defer { lock.unlock() }
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
        lock.lock()
        defer { lock.unlock() }
        guard index < state.secretWallets.count else { return }
        state.currentWallet = state.secretWallets[index]
    }
    
    func activateDefaultWallet() {
        lock.lock()
        defer { lock.unlock() }
        state.currentWallet = state.defaultWallet
    }
}
