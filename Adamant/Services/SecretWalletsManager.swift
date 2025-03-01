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
        /// Where 0 is regular wallet and 1... are secret wallets
        var wallets: [WalletStoreServiceProtocol] = []
    }
}

final class AdamantSecretWalletsManager: SecretWalletsManagerProtocol {
    private let secretWalletsFactory: SecretWalletsFactory
    private let lock = NSLock()
    
    private var state: SecretWalletsManagerStateProtocol
    var statePublisher = ObservableSender<SecretWalletsManagerStateProtocol>()
    
    private(set) var currentWalletIndex: Int = 0
    
    init(
        walletsStoreService: WalletStoreServiceProtocol,
        secretWalletsFactory: SecretWalletsFactory
    ) {
        self.state = State(
            currentWallet: walletsStoreService,
            wallets: [walletsStoreService]
        )
        self.secretWalletsFactory = secretWalletsFactory
    }
    
    // MARK: - Manage state
    func createSecretWallet(withPassword password: String) {
        let wallet = secretWalletsFactory.makeSecretWallet(withPassword: password)
        lock.lock()
        defer { lock.unlock() }
        state.wallets.append(wallet)
    }
    
    func removeSecretWallet(at index: Int) -> WalletStoreServiceProtocol? {
        lock.lock()
        defer { lock.unlock() }
        guard index == 0 || state.wallets.indices.contains(index) else { return nil }
        return state.wallets.remove(at: index)
    }
    
    func getCurrentWallet() -> WalletStoreServiceProtocol {
        state.currentWallet
    }
    
    func getSecretWallets() -> [WalletStoreServiceProtocol] {
        state.wallets
    }
    
    func getCurrentWalletIndex() -> Int {
        currentWalletIndex
    }
    
    func activateWallet(at index: Int) {
        lock.lock()
        defer { lock.unlock() }
        guard index < state.wallets.count else { return }
        state.currentWallet = state.wallets[index]
        currentWalletIndex = index
        statePublisher.send(state)
    }
}
