//
//  AdamantVisibleWalletsService.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 16.12.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import Combine
import CommonKit
import Foundation

final class AdamantVisibleWalletsService: VisibleWalletsService, @unchecked Sendable {
    
    // MARK: Dependencies
    let SecureStore: SecureStore
    let accountService: AccountService
    let walletsServiceCompose: WalletServiceCompose
    
    // MARK: Proprieties
    
    private enum Types {
        case indexes
        case visibility
        
        var path: String {
            switch self {
                case .indexes: return StoreKey.visibleWallets.useCustomIndexes
                case .visibility: return StoreKey.visibleWallets.useCustomVisibility
            }
        }
    }
    
    @Atomic private var notificationsSet: Set<AnyCancellable> = []
    
    @ObservableValue private var state: AdamantVisibleWalletsServiceState
    var statePublisher: AnyObservable<Void> {
        $state.map { _ in }.eraseToAnyPublisher()
    }
    
    // MARK: Lifecycle
    init(
        SecureStore: SecureStore,
        accountService: AccountService,
        walletsServiceCompose: WalletServiceCompose
    ) {
        self.SecureStore = SecureStore
        self.accountService = accountService
        self.walletsServiceCompose = walletsServiceCompose
        self.state = .init()
        
        NotificationCenter.default
            .notifications(named: .AdamantAccountService.userLoggedOut)
            .sink { [weak self] _ in
                self?.userLoggedOut()
            }
            .store(in: &notificationsSet)
        
        NotificationCenter.default
            .notifications(named: .AdamantAccountService.userLoggedIn)
            .sink { [weak self] _ in
                self?.userLoggedIn()
            }
            .store(in: &notificationsSet)
    }
    
    // MARK: Notification actions
    
    private func userLoggedIn() {
        state.invisibleWallets = getInvisibleWallets()
        state.indexesWallets = getSortedWallets(includeInvisible: false)
    }
    
    private func userLoggedOut() {
        SecureStore.remove(StoreKey.visibleWallets.invisibleWallets)
        SecureStore.remove(StoreKey.visibleWallets.indexWallets)
        SecureStore.remove(StoreKey.visibleWallets.useCustomIndexes)
        SecureStore.remove(StoreKey.visibleWallets.useCustomVisibility)
        state.invisibleWallets.removeAll()
        state.indexesWallets.removeAll()
    }
    
    // MARK: Visible
    
    func addToInvisibleWallets(_ walletTokenUniqueID: String) {
        var wallets = getInvisibleWallets()
        wallets.append(walletTokenUniqueID)
        setInvisibleWallets(wallets)
    }
    
    func removeFromInvisibleWallets(_ walletTokenUniqueID: String) {
        var wallets = getInvisibleWallets()
        guard let index = wallets.firstIndex(of: walletTokenUniqueID) else { return }
        wallets.remove(at: index)
        setInvisibleWallets(wallets)
    }
    
    private func getInvisibleWallets() -> [String] {
        guard isUseCustomFilter(for: .visibility) else {
            let wallets = walletsServiceCompose.getWallets()
                .filter { $0.core.defaultVisibility != true }
                .map { $0.core.tokenUniqueID }
            return wallets
        }
        
        return SecureStore.get(StoreKey.visibleWallets.invisibleWallets) ?? []
    }
    
    func isInvisible(_ walletTokenUniqueID: String) -> Bool {
        state.invisibleWallets.contains(walletTokenUniqueID)
    }
    
    private func setInvisibleWallets(_ wallets: [String]) {
        SecureStore.set(wallets, for: StoreKey.visibleWallets.invisibleWallets)
        setUseCustomFilter(for: .visibility, value: true)
        state.invisibleWallets = getInvisibleWallets()
    }
    
    // MARK: Index Positions
    
    func getSortedWallets(includeInvisible: Bool) -> [String] {
        guard isUseCustomFilter(for: .indexes) else {
            // Sort by default ordinal number
            // Coins without an order are shown last, alphabetically
            let wallets = walletsServiceCompose.getWallets().map { $0.core }
            let walletsIV =
            includeInvisible
            ? wallets
            : wallets.filter { $0.defaultVisibility == true }
            
            
            var walletsWithIndexes =
            walletsIV
                .filter { $0.defaultOrdinalLevel != nil }
                .sorted(by: { $0.defaultOrdinalLevel! < $1.defaultOrdinalLevel! })
            let walletsWithNoIndexes =
            walletsIV
                .filter { $0.defaultOrdinalLevel == nil }
                .sorted(by: { $0.tokenName < $1.tokenName })
            
            walletsWithIndexes.append(contentsOf: walletsWithNoIndexes)
            
            return walletsWithIndexes.map { $0.tokenUniqueID }
        }
        
        let path =
        includeInvisible
        ? StoreKey.visibleWallets.indexWalletsWithInvisible
        : StoreKey.visibleWallets.indexWallets
        
        guard let indexes: [String] = SecureStore.get(path) else {
            return []
        }
        return indexes
    }
    
    func setIndexPositionWallets(_ wallets: [String], includeInvisible: Bool) {
        let path =
        includeInvisible
        ? StoreKey.visibleWallets.indexWalletsWithInvisible
        : StoreKey.visibleWallets.indexWallets
        
        SecureStore.set(wallets, for: path)
        state.indexesWallets = getSortedWallets(includeInvisible: false)
        setUseCustomFilter(for: .indexes, value: true)
        
    }
    
    func reset() {
        setUseCustomFilter(for: .indexes, value: false)
        setUseCustomFilter(for: .visibility, value: false)
        state.indexesWallets = getSortedWallets(includeInvisible: false)
        state.invisibleWallets = getInvisibleWallets()
    }
    
    private func isUseCustomFilter(for type: Types) -> Bool {
        guard let result: Bool = SecureStore.get(type.path) else {
            return false
        }
        return result
    }
    
    private func setUseCustomFilter(for type: Types, value: Bool) {
        SecureStore.set(value, for: type.path)
    }
}
