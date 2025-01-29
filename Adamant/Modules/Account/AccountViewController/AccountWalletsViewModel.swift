//
//  AccountWalletsViewModel.swift
//  Adamant
//
//  Created by Dmitrij Meidus on 29.01.25.
//  Copyright © 2025 Adamant. All rights reserved.
//

import Foundation
import CommonKit
import Combine

@MainActor
final class AccountWalletsViewModel {
    @ObservableValue var state: AccountWalletsState = .default
    
    private let compose: WalletServiceCompose
    private var subscriptions = Set<AnyCancellable>()
    
    init(compose: WalletServiceCompose) {
        self.compose = compose
        setup()
    }
}

private extension AccountWalletsViewModel {
    func setup() {
        addObservers()
    }
    
    func addObservers() {
        for wallet in compose.getWallets() {
            wallet.core.walletUpdatePublisher.sink { [weak self] _ in
                self?.updateInfo(wallet)
            }.store(in: &subscriptions)
        }
    }
    
    func updateInfo(_ wallet: WalletService) {
        guard
            let index = state.wallets.firstIndex(
                where: { $0.coinID == wallet.core.tokenUnicID }
            )
        else { return }
        
        state.wallets[index].address = wallet.core.wallet?.address ?? .empty
        state.wallets[index].balance = wallet.core.wallet?.balance ?? 0
        state.wallets[index].notificationBadgeCount = wallet.core.wallet?.notifications ?? 0
    }
}
