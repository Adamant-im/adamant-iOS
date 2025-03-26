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
import Combine

private extension AdamantSecretWalletsManager {
    struct State: SecretWalletsManagerStateProtocol {
        var currentWallet: WalletStoreServiceProtocol
        var regularWallet: WalletStoreServiceProtocol
        var secretWallets: [WalletStoreServiceProtocol] = []
    }
}

final class AdamantSecretWalletsManager: SecretWalletsManagerProtocol {
    private let secretWalletsFactory: SecretWalletsFactory
    
    private var state: SecretWalletsManagerStateProtocol
    var statePublisher = ObservableSender<SecretWalletsManagerStateProtocol>()
    
    var wallets: [WalletStoreServiceProtocol] { [state.regularWallet] + state.secretWallets }
    
    private let lock = NSLock()
    private var subscriptions = Set<AnyCancellable>()
    
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
        statePublisher.send(state)
    }
    
    func activateDefaultWallet() {
        lock.lock()
        defer { lock.unlock() }
        state.currentWallet = state.regularWallet
        statePublisher.send(state)
    }
    
    func removeAllSecretWallets() {
        lock.lock()
        defer { lock.unlock() }
        state.secretWallets.removeAll()
    }
}
