//
//  AccountWalletsViewModel.swift
//  Adamant
//
//  Created by Dmitrij Meidus on 29.01.25.
//  Copyright © 2025 Adamant. All rights reserved.
//

import Combine
import CommonKit
import Foundation

@MainActor
final class AccountWalletsViewModel {
    @ObservableValue var state: AccountWalletsState = .default

    private let walletsStoreService: WalletStoreServiceProviderProtocol
    private var walletSubscriptions: Set<AnyCancellable> = []
    private var currentWalletPublisherSubscription: Set<AnyCancellable> = []
    
    init(walletsStoreService: WalletStoreServiceProviderProtocol) {
        self.walletsStoreService = walletsStoreService
        setup()
    }
}

extension AccountWalletsViewModel {
    fileprivate func setup() {
        addObservers()
    }
    
    func addObservers() {
        walletsStoreService.currentWalletPublisher
            .sink(
                receiveValue: { [weak self] _ in
                    self?.updateState()
                }
            )
            .store(in: &currentWalletPublisherSubscription)
    }
    
    func addWalletObservers() {
        for wallet in walletsStoreService.sorted(includeInvisible: false) {
            updateInfo(for: wallet)
            wallet.core.walletUpdatePublisher
                .sink(
                    receiveValue: { [weak self] _ in
                        self?.updateInfo(for: wallet)
                    }
                )
                .store(in: &walletSubscriptions)
        }
    }
    
    func updateInfo(for wallet: WalletService) {
        let coreService = wallet.core
        if let index = state.wallets.firstIndex(where: { $0.coinID == coreService.tokenUniqueID }) {
            state.wallets[index].balance = coreService.wallet?.balance ?? 0
            state.wallets[index].isBalanceInitialized = coreService.wallet?.isBalanceInitialized ?? false
            state.wallets[index].notificationBadgeCount = coreService.wallet?.notifications ?? 0
        } else {
            let network = type(of: coreService).tokenNetworkSymbol

            let model = WalletCollectionViewCell.Model(
                index: state.wallets.count,
                coinID: coreService.tokenUniqueID,
                currencySymbol: coreService.tokenSymbol,
                currencyImage: coreService.tokenLogo,
                currencyNetwork: network,
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
        walletSubscriptions.removeAll()
        state.wallets.removeAll()
        addWalletObservers()
    }
}
