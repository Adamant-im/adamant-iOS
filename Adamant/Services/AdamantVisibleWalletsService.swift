//
//  AdamantVisibleWalletsService.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 16.12.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import Foundation
import Combine
import CommonKit

final class AdamantVisibleWalletsService: VisibleWalletsService, @unchecked Sendable {
    
    // MARK: Dependencies
    let securedStore: SecuredStore
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
    
    @Atomic private var invisibleWallets: [String] = []
    @Atomic private var indexesWallets: [String] = []
    @Atomic private var notificationsSet: Set<AnyCancellable> = []
    
    // MARK: Lifecycle
    init(
        securedStore: SecuredStore,
        accountService: AccountService,
        walletsServiceCompose: WalletServiceCompose
    ) {
        self.securedStore = securedStore
        self.accountService = accountService
        self.walletsServiceCompose = walletsServiceCompose
        
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
        invisibleWallets = getInvisibleWallets()
        indexesWallets = getSortedWallets(includeInvisible: false)
        
        NotificationCenter.default.post(
            name: Notification.Name.AdamantVisibleWalletsService.visibleWallets,
            object: nil
        )
    }
    
    private func userLoggedOut() {
        securedStore.remove(StoreKey.visibleWallets.invisibleWallets)
        securedStore.remove(StoreKey.visibleWallets.indexWallets)
        securedStore.remove(StoreKey.visibleWallets.useCustomIndexes)
        securedStore.remove(StoreKey.visibleWallets.useCustomVisibility)
        invisibleWallets.removeAll()
        indexesWallets.removeAll()
        
        NotificationCenter.default.post(
            name: Notification.Name.AdamantVisibleWalletsService.visibleWallets,
            object: nil
        )
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
        
        guard let wallets: [String] = securedStore.get(StoreKey.visibleWallets.invisibleWallets) else {
            return []
        }
        return wallets
    }
    
    func isInvisible(_ walletTokenUniqueID: String) -> Bool {
        invisibleWallets.contains(walletTokenUniqueID)
    }
    
    private func setInvisibleWallets(_ wallets: [String]) {
        securedStore.set(wallets, for: StoreKey.visibleWallets.invisibleWallets)
        setUseCustomFilter(for: .visibility, value: true)
        invisibleWallets = getInvisibleWallets()
    }
    
    // MARK: Index Positions
    
    func getSortedWallets(includeInvisible: Bool) -> [String] {
        guard isUseCustomFilter(for: .indexes) else {
            // Sort by default ordinal number
            // Coins without an order are shown last, alphabetically
            let wallets = walletsServiceCompose.getWallets().map { $0.core }
            let walletsIV = includeInvisible
            ? wallets
            : wallets.filter { $0.defaultVisibility == true }
            
            var walletsWithIndexes = walletsIV
                .filter { $0.defaultOrdinalLevel != nil }
                .sorted(by: { $0.defaultOrdinalLevel! < $1.defaultOrdinalLevel! })
            let walletsWithNoIndexes = walletsIV
                .filter { $0.defaultOrdinalLevel == nil }
                .sorted(by: { $0.tokenName < $1.tokenName })
            
            walletsWithIndexes.append(contentsOf: walletsWithNoIndexes)

            return walletsWithIndexes.map { $0.tokenUniqueID }
        }
        
        let path = !includeInvisible
        ? StoreKey.visibleWallets.indexWallets
        : StoreKey.visibleWallets.indexWalletsWithInvisible
        
        guard let indexes: [String] = securedStore.get(path) else {
            return []
        }
        return indexes
    }
    
    func setIndexPositionWallets(_ wallets: [String], includeInvisible: Bool) {
        let path = !includeInvisible
        ? StoreKey.visibleWallets.indexWallets
        : StoreKey.visibleWallets.indexWalletsWithInvisible
        
        securedStore.set(wallets, for: path)
        indexesWallets = getSortedWallets(includeInvisible: false)
        setUseCustomFilter(for: .indexes, value: true)
        
    }
    
    func reset() {
        setUseCustomFilter(for: .indexes, value: false)
        setUseCustomFilter(for: .visibility, value: false)
        indexesWallets = getSortedWallets(includeInvisible: false)
        invisibleWallets = getInvisibleWallets()
        NotificationCenter.default.post(name: Notification.Name.AdamantVisibleWalletsService.visibleWallets, object: nil)
    }
    
    private func isUseCustomFilter(for type: Types) -> Bool {
        guard let result: Bool = securedStore.get(type.path) else {
            return false
        }
        return result
    }
    
    private func setUseCustomFilter(for type: Types, value: Bool) {
        securedStore.set(value, for: type.path)
    }
}
