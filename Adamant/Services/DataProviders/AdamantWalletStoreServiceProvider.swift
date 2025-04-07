//
//  AdamantWalletStoreServiceProvider.swift
//  Adamant
//
//  Created by Dmitrij Meidus on 08.02.25.
//  Copyright © 2025 Adamant. All rights reserved.
//

import Combine
import CommonKit
import Foundation

protocol WalletStoreServiceProviderProtocol: WalletStoreServiceProtocol {
    @MainActor
    var currentWalletPublisher: AnyObservable<Void> { get }
}

final class AdamantWalletStoreServiceProvider: WalletStoreServiceProviderProtocol {
    private let secretWalletsManager: SecretWalletsManagerProtocol

    private var cancellables = Set<AnyCancellable>()

    @ObservableValue private var currentWallet: WalletStoreServiceProtocol
    var currentWalletPublisher: AnyObservable<Void> {
        $currentWallet.map { _ in () }.eraseToAnyPublisher()
    }

    init(secretWalletsManager: SecretWalletsManagerProtocol) {
        self.secretWalletsManager = secretWalletsManager
        self._currentWallet = ObservableValue(secretWalletsManager.getCurrentWallet())

        setupBindings()
    }

    private func setupBindings() {
        secretWalletsManager.statePublisher
            .map { $0.currentWallet }
            .receive(on: DispatchQueue.main)
            .assign(to: _currentWallet)
            .store(in: &cancellables)
    }

    func sorted(includeInvisible: Bool) -> [WalletService] {
        currentWallet.sorted(includeInvisible: includeInvisible)
    }

    func isInvisible(_ wallet: WalletService) -> Bool {
        currentWallet.isInvisible(wallet)
    }
}
