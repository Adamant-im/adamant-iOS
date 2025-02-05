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
    
    private let walletsService: VisibleWalletsService
    private var subscriptions = Set<AnyCancellable>()
    
    init(walletsService: VisibleWalletsService) {
        self.walletsService = walletsService
        setup()
    }
}

private extension AccountWalletsViewModel {
    func setup() {
        addObservers()
    }
    
    func addObservers() {
        for wallet in walletsService.sorted(includeInvisible: false) {
            updateInfo(for: wallet)
            wallet.core.walletUpdatePublisher
                .sink(
                    receiveValue: { [weak self] _ in
                        self?.updateInfo(for: wallet)
                    }
                )
                .store(in: &subscriptions)
        }
    }

    func updateInfo(for wallet: WalletService) {
        let coreService = wallet.core
        if let index = state.wallets.firstIndex(where: { $0.coinID == coreService.tokenUniqueID }) {
            state.wallets[index].balance = coreService.wallet?.balance ?? 0
            state.wallets[index].isBalanceInitialized = coreService.wallet?.isBalanceInitialized ?? false
            state.wallets[index].notificationBadgeCount = coreService.wallet?.notifications ?? 0
        } else {
            let model = WalletCollectionViewCell.Model(
                index: state.wallets.count,
                coinID: coreService.tokenUniqueID,
                currencySymbol: coreService.tokenSymbol,
                currencyImage: coreService.tokenLogo,
                currencyNetwork: type(of: coreService).tokenNetworkSymbol,
                isBalanceInitialized: coreService.wallet?.isBalanceInitialized ?? false,
                balance: coreService.wallet?.balance ?? 0,
                notificationBadgeCount: coreService.wallet?.notifications ?? 0
            )
            
            state.wallets.append(model)
        }
    }
}

extension AccountWalletsViewModel {
    func updateState() {
        subscriptions.removeAll()
        state.wallets.removeAll()
        setup()
    }
}
