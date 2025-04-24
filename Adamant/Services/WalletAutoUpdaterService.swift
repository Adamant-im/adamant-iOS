//
//  WalletAutoUpdaterService.swift
//  Adamant
//
//  Created by Dmitrij Meidus on 16.04.25.
//  Copyright © 2025 Adamant. All rights reserved.
//

import Foundation
import Combine

/// Actor responsible for orchestrating automatic wallet updates throughout the app lifecycle.
///
/// After you call `start()`, it listens for:
/// 1. **Login / Logout** via NotificationCenter:
///    - On login it waits 0.5 s and then sets up subscriptions.
///    - On logout it tears down all scheduling state.
/// 2. **Wallet list changes** via `walletStoreServiceProvider.currentWalletPublisher`:
///    - Fully reinitializes its internal wallet registry whenever the set of available wallets changes.
/// 3. **Visibility changes** via `visibleWalletService.statePublisher`:
///    - Adjusts which wallets are actively scheduled for periodic updates.
///
/// For each visible wallet, it uses `repeaterService` to register a recurring `update()` call at a
/// wallet‑type‑specific interval (shorter for new ADM accounts, longer for BTC/KLY, etc.), and
/// unregisters any tasks when wallets go out of scope or the user logs out.
actor WalletAutoUpdateService {
    private let visibleWalletService: VisibleWalletsService
    private let walletStoreServiceProvider: WalletStoreServiceProviderProtocol
    private let repeaterService: RepeaterService
    
    private let accountService: AccountService
    
    private var cancellables = Set<AnyCancellable>()
    private var notificationCancellables = Set<AnyCancellable>()
    private var walletsRepetitions = Set<String>()
    
   init(
        visibleWalletService: VisibleWalletsService,
        walletStoreServiceProvider: WalletStoreServiceProviderProtocol,
        repeaterService: RepeaterService,
        accountService: AccountService
    ) {
        self.visibleWalletService = visibleWalletService
        self.walletStoreServiceProvider = walletStoreServiceProvider
        self.repeaterService = repeaterService
        self.accountService = accountService
    }
    
    func start(){
        NotificationCenter.default
            .notifications(named: .AdamantAccountService.userLoggedIn)
            .sink { [weak self] _ in
                Task {
                    guard let self = self else { return }
                    try? await Task.sleep(interval: 0.5)
                    await self.setup()
                }
            }
            .store(in: &notificationCancellables)
        
        NotificationCenter.default
            .notifications(named: .AdamantAccountService.userLoggedOut)
            .sink { [weak self] _ in
                Task {
                    guard let self = self else { return }
                    await self.removeState()
                }
            }
            .store(in: &notificationCancellables)
    }
    
    private func setup() async {
        await walletStoreServiceProvider.currentWalletPublisher
            .sink { [weak self] _ in
                guard let self = self else { return }
                Task {
                    await self.reinit()
                }
            }
            .store(in: &cancellables)
    }
    
    private func reinit() async {
        self.walletsRepetitions.removeAll()
        visibleWalletService.statePublisher
            .sink { [weak self] _ in
                guard let self = self else { return }
                Task { await self.updateRepetitions() }
            }
            .store(in: &cancellables)
    }
    
    private func updateRepetitions() async {
        let currentWallets = walletStoreServiceProvider.sorted(includeInvisible: false)
        
        let oldReps = walletsRepetitions
        var newReps: Set<String> = []
        
        for wallet in currentWallets {
            let id = wallet.core.tokenUniqueID
            let core = wallet.core
            newReps.insert(id)
            guard !oldReps.contains(id) else {
                continue 
            }
            
            repeaterService.registerForegroundCall(
                label: id,
                interval: getTimeIntervalFor(wallet: core),
                queue: .global(qos: .utility),
                callback: {
                    core.update()
                }
            )
        }
        
        self.walletsRepetitions = newReps
        
        guard oldReps.count > 0 else { return }
        
        let toRemove = oldReps.subtracting(newReps)
        for id in toRemove {
            repeaterService.unregisterForegroundCall(label: id)
        }
    }
    
    func removeState() {
        for id in walletsRepetitions {
            repeaterService.unregisterForegroundCall(label: id)
        }
        walletsRepetitions.removeAll()
        cancellables.removeAll()
    }
    
    private func getTimeIntervalFor(wallet: WalletCoreProtocol) -> TimeInterval {
        if let isNewAccount = accountService.account?.isNewAccount, isNewAccount {
            if let wallet = wallet as? AdmWalletService {
                return Double(wallet.balanceCheckIntervalNewAccount ?? 50000) / 1000
            }
        }
        return Double(wallet.balanceCheckInterval ?? 50000) / 1000
    }
}
