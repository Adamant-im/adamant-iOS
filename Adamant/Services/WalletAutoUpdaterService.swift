//
//  WalletAutoUpdaterService.swift
//  Adamant
//
//  Created by Dmitrij Meidus on 16.04.25.
//  Copyright © 2025 Adamant. All rights reserved.
//

import Foundation
import Combine

/// Actor responsible for managing and scheduling automatic wallet updates.
///
/// Listens to two primary event streams:
/// 1. `visibleWalletService.statePublisher` — adjusts the set of active update tasks whenever wallet visibility changes.
/// 2. `walletStoreServiceProvider.currentWalletPublisher` — fully reinitializes all update tasks whenever the underlying wallet list changes.
///
/// For each visible wallet, uses `repeaterService` to register or unregister a background callback
/// `updateWithRefreshUIBalance()` at an interval determined by the wallet’s type.
actor WalletAutoUpdateService {
    private let visibleWalletService: VisibleWalletsService
    private let walletStoreServiceProvider: WalletStoreServiceProviderProtocol
    private let repeaterService: RepeaterService
    
    private var cancellables = Set<AnyCancellable>()
    private var notificationCancellables = Set<AnyCancellable>()
    private var walletsRepetitions = Set<String>()
    
    init(
        visibleWalletService: VisibleWalletsService,
        walletStoreServiceProvider: WalletStoreServiceProviderProtocol,
        repeaterService: RepeaterService
    ) {
        self.visibleWalletService = visibleWalletService
        self.walletStoreServiceProvider = walletStoreServiceProvider
        self.repeaterService = repeaterService
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
                    print("[\(Date())] " + "updating wallet: \(id)" + "\n----------------------")
                    core.updateWithRefreshUIBalance()
                }
            )
        }
        
        self.walletsRepetitions = newReps
        
        guard oldReps.count > 0 else { return }
        
        let toRemove = oldReps.subtracting(newReps)
        for id in toRemove {
            print("unregistering: \(id)")
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
        switch wallet {
            case is AdmWalletService:
                return WalletsUpdateConstants.adm.rawValue
            case is EthWalletService:
                return WalletsUpdateConstants.erc20.rawValue
            case is ERC20WalletService:
                return WalletsUpdateConstants.erc20.rawValue
            case is DashWalletService:
                return WalletsUpdateConstants.dash.rawValue
            case is DogeWalletService:
                return WalletsUpdateConstants.doge.rawValue
            case is BtcWalletService:
                return WalletsUpdateConstants.btc.rawValue
            case is KlyWalletService:
                return WalletsUpdateConstants.kly.rawValue
            default:
                return 50
        }
    }
    
    private enum WalletsUpdateConstants: TimeInterval {
        case adm = 5
        case erc20, dash = 25
        case doge = 30
        case btc, kly = 50
        case admNewAccount = 2
    }
}
