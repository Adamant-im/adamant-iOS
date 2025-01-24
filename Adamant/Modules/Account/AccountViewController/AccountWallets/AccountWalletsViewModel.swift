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
    
    func updateWallet(withId id: String, model: WalletItemModel) {
        self.state.walletModels[id] = model
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
            NotificationCenter.default.addObserver(
                forName: walletService.core.walletUpdatedNotification,
                object: nil,
                queue: OperationQueue.main,
                using: { [weak self] notification in
                    MainActor.assumeIsolatedSafe {
                        self?.handleWalletUpdate(notification)
                    }
                }
            )
        }
    }
    
    private func handleWalletUpdate(_ notification: Notification) {
        guard let account = notification.userInfo?[AdamantUserInfoKey.WalletService.wallet] as? WalletAccount else {
            return
        }
        
        var model = state.walletModels[account.unicId]?.model
        model?.balance = account.balance
        model?.isBalanceInitialized = account.isBalanceInitialized
        model?.notifications = account.notifications
        
        updateWallet(withId: account.unicId, model: WalletItemModel(model: model ?? .default))
    }
}
