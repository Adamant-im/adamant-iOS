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
    private let screensFactory: ScreensFactory
    private(set) var walletControllers: [String: WalletViewController] = [:]
    private var subscriptions = Set<AnyCancellable>()
    
    init(walletsService: VisibleWalletsService, screensFactory: ScreensFactory) {
        self.walletsService = walletsService
        self.screensFactory = screensFactory
        setup()
    }
    
    func updateState(byIndex index: Int, model: WalletCollectionViewCell.Model) {
        guard index < state.wallets.count else { return }
        
        state.wallets[index] = model
    }
}

private extension AccountWalletsViewModel {
    func setup() {
        for wallet in walletsService.sorted(includeInvisible: false) {
            addObserver(for: wallet)
            walletControllers[wallet.core.tokenUnicID] = screensFactory.makeWalletVC(service: wallet)
        }
    }
    
    func addObserver(for wallet: WalletService) {
            updateInfo(wallet)
            wallet.core.walletUpdatePublisher
                .sink(
                    receiveValue: { [weak self] _ in
                        self?.updateInfo(wallet)
                    }
                )
                .store(in: &subscriptions)
    }

    
    func updateInfo(_ wallet: WalletService) {
        if let index = state.wallets.firstIndex(where: { $0.coinID == wallet.core.tokenUnicID }) {
            state.wallets[index].balance = wallet.core.wallet?.balance ?? 0
            state.wallets[index].isBalanceInitialized = wallet.core.wallet?.isBalanceInitialized ?? false
            state.wallets[index].notificationBadgeCount = wallet.core.wallet?.notifications ?? 0
            
        } else {
            let service = wallet.core
            
            let model = WalletCollectionViewCell.Model(
                index: state.wallets.count,
                coinID: service.tokenUnicID,
                currencySymbol: service.tokenSymbol,
                currencyImage: service.tokenLogo,
                currencyNetwork: type(of: service).tokenNetworkSymbol,
                isBalanceInitialized: service.wallet?.isBalanceInitialized ?? false,
                balance: service.wallet?.balance ?? 0,
                notificationBadgeCount: service.wallet?.notifications ?? 0
            )
            
            state.wallets.append(model)
        }
    }
}

extension AccountWalletsViewModel{
    func getWalletViewController(forIndex index: Int) -> WalletViewController? {
        guard index < state.wallets.count else { return nil }
        return walletControllers[state.wallets[index].coinID]
    }
}
