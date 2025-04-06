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
    var state: AccountWalletsState = .default
    
    private let walletsStoreService: WalletStoreServiceProviderProtocol
    private var subscriptions = Set<AnyCancellable>()

    init(walletsStoreService: WalletStoreServiceProviderProtocol) {
        self.walletsStoreService = walletsStoreService
        setup()
    }
}

extension AccountWalletsViewModel {
    fileprivate func setup() {
        addObservers()
    }

    fileprivate func addObservers() {
        for wallet in walletsStoreService.sorted(includeInvisible: false) {
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

    fileprivate func updateInfo(for wallet: WalletService) {
        let coreService = wallet.core
        let tokenID = coreService.tokenUniqueID
        if let index = state.wallets.firstIndex(where: { $0.model.coinID == tokenID }) {
            let cellState = state.wallets[index]
            var newModel = cellState.model
            newModel.balance = coreService.wallet?.balance ?? 0
            newModel.isBalanceInitialized = coreService.wallet?.isBalanceInitialized ?? false
            newModel.notificationBadgeCount = coreService.wallet?.notifications ?? 0
            cellState.model = newModel
            state.wallets[index] = cellState
        } else {
            let network = type(of: coreService).tokenNetworkSymbol
            let newModel = WalletCollectionViewCellModel(
                index: state.wallets.count,
                coinID: tokenID,
                currencySymbol: coreService.tokenSymbol,
                currencyImage: coreService.tokenLogo,
                currencyNetwork: network,
                isBalanceInitialized: coreService.wallet?.isBalanceInitialized ?? false,
                balance: coreService.wallet?.balance ?? 0,
                notificationBadgeCount: coreService.wallet?.notifications ?? 0
            )
            let cellState = AccountWalletCellState(model: newModel)
            state.wallets.append(cellState)
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
