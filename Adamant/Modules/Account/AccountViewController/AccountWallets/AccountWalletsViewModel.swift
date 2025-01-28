//
//  WalletsState.swift
//  Adamant
//
//  Created by Dmitrij Meidus on 24.01.25.
//  Copyright © 2025 Adamant. All rights reserved.
//

import Foundation
import Combine
import CommonKit

@MainActor
final class AccountWalletsViewModel: ObservableObject {
    @ObservableValue var state: AccountWalletsState
    private let walletServiceCompose: WalletServiceCompose
    
    private var subscriptions = Set<AnyCancellable>()

    init(state: AccountWalletsState, walletServiceCompose: WalletServiceCompose) {
        self.state = state
        self.walletServiceCompose = walletServiceCompose
        observeWalletUpdates()
    }
    
    func observeStateChanges(onChange: @escaping @MainActor () -> Void) {
        $state
            .receive(on: DispatchQueue.main)
            .sink { _ in
                onChange()
            }
            .store(in: &subscriptions)
    }
    
    private func observeWalletUpdates() {
        for walletService in walletServiceCompose.getWallets() {
            walletService.core.walletPublisher
                .compactMap { $0 }
                .sink { [weak self] walletAccount in
                    self?.handleWalletUpdate(for: walletAccount)
                }
                .store(in: &subscriptions)
        }
    }
    
    private func handleWalletUpdate(for newWallet: WalletAccount) {
        var model = state.walletModels[newWallet.unicId]?.model
        model?.balance = newWallet.balance
        model?.isBalanceInitialized = newWallet.isBalanceInitialized
        model?.notifications = newWallet.notifications
        
        let walletModel = WalletItemModel(model: model ?? .default)
        updateWallet(withId: newWallet.unicId, model: walletModel)
    }

    func updateWallet(withId id: String, model: WalletItemModel) {
        self.state.walletModels[id] = model
    }
}
