//
//  AdamantVisibleWalletsService.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 16.12.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import Foundation

class AdamantVisibleWalletsService: VisibleWalletsService {
    
    // MARK: Dependencies
    let securedStore: SecuredStore
    let accountService: AccountService
    
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
    
    private var invisibleWallets: [String] = []
    private var indexesWallets: [String] = []
    
    // MARK: Lifecycle
    init(securedStore: SecuredStore, accountService: AccountService) {
        self.securedStore = securedStore
        self.accountService = accountService
        
        NotificationCenter.default.addObserver(forName: Notification.Name.AdamantAccountService.userLoggedOut, object: nil, queue: nil) { [weak self] _ in
            self?.securedStore.remove(StoreKey.visibleWallets.invisibleWallets)
            self?.securedStore.remove(StoreKey.visibleWallets.indexWallets)
            self?.securedStore.remove(StoreKey.visibleWallets.useCustomIndexes)
            self?.securedStore.remove(StoreKey.visibleWallets.useCustomVisibility)
            NotificationCenter.default.post(name: Notification.Name.AdamantVisibleWalletsService.visibleWallets, object: nil)
        }
        
        NotificationCenter.default.addObserver(forName: Notification.Name.AdamantAccountService.userLoggedIn, object: nil, queue: nil) { [weak self] _ in
            self?.invisibleWallets = self?.getInvisibleWallets() ?? []
            self?.indexesWallets = self?.getSortedWallets(includeInvisible: false) ?? []
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: Visible
    
    func addToInvisibleWallets(_ wallet: WalletService) {
        var wallets = getInvisibleWallets()
        wallets.append(wallet.tokenUnicID)
        setInvisibleWallets(wallets)
    }
    
    func removeFromInvisibleWallets(_ wallet: WalletService) {
        var wallets = getInvisibleWallets()
        guard let index = wallets.firstIndex(of: wallet.tokenUnicID) else { return }
        wallets.remove(at: index)
        setInvisibleWallets(wallets)
    }
    
    func getInvisibleWallets() -> [String] {
        guard isUseCustomFilter(for: .visibility) else {
            let wallets = accountService.wallets.filter { $0.defaultVisibility != true }.map { $0.tokenUnicID }
            return wallets
        }
        
        guard let wallets: [String] = securedStore.get(StoreKey.visibleWallets.invisibleWallets) else {
            return []
        }
        return wallets
    }
    
    func isInvisible(_ wallet: WalletService) -> Bool {
        return invisibleWallets.contains(wallet.tokenUnicID)
    }
    
    private func setInvisibleWallets(_ wallets: [String]) {
        securedStore.set(wallets, for: StoreKey.visibleWallets.invisibleWallets)
        setUseCustomFilter(for: .visibility, value: true)
        invisibleWallets = getInvisibleWallets()
    }
    
    // MARK: Index Positions
    
    func getIndexPosition(for wallet: WalletService) -> Int? {
        return indexesWallets.firstIndex(of: wallet.tokenUnicID)
    }
    
    func getSortedWallets(includeInvisible: Bool) -> [String] {
        guard isUseCustomFilter(for: .indexes) else {
            // Sort by default ordinal number
            // Coins without an order are shown last, alphabetically
            let walletsIV = includeInvisible ? accountService.wallets : accountService.wallets.filter { $0.defaultVisibility == true }
            var walletsWithIndexes = walletsIV.filter { $0.defaultOrdinalLevel != nil }.sorted(by: { $0.defaultOrdinalLevel! < $1.defaultOrdinalLevel! })
            let walletsWithNoIndexes = walletsIV.filter { $0.defaultOrdinalLevel == nil }.sorted(by: { $0.tokenName < $1.tokenName })
            
            walletsWithIndexes.append(contentsOf: walletsWithNoIndexes)

            let wallets = walletsWithIndexes.map({ $0.tokenUnicID })
            return wallets
        }
        
        let path = !includeInvisible ? StoreKey.visibleWallets.indexWallets : StoreKey.visibleWallets.indexWalletsWithInvisible
        guard let indexes: [String] = securedStore.get(path) else {
            return []
        }
        return indexes
    }
    
    func setIndexPositionWallets(_ wallets: [String], includeInvisible: Bool) {
        let path = !includeInvisible ? StoreKey.visibleWallets.indexWallets : StoreKey.visibleWallets.indexWalletsWithInvisible
        securedStore.set(wallets, for: path)
        indexesWallets = getSortedWallets(includeInvisible: false)
        setUseCustomFilter(for: .indexes, value: true)
    }
    
    func setIndexPositionWallets(_ wallets: [WalletService], includeInvisible: Bool) {
        let wallets = includeInvisible ? wallets : wallets.filter { !isInvisible($0) }
        let walletsUnicsId = wallets.map({ $0.tokenUnicID })

        setIndexPositionWallets(walletsUnicsId, includeInvisible: includeInvisible)
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
    
    // MARK: - Sort by indexes
    
    func sorted<T>(includeInvisible: Bool) -> [T] {
        var availableServices = includeInvisible
        ? accountService.wallets
        : accountService.wallets.filter { !isInvisible($0) }
        
        for (newIndex, tokenUnicID) in getSortedWallets(includeInvisible: includeInvisible).enumerated() {
            guard let index = availableServices.firstIndex(where: { wallet in
                return wallet.tokenUnicID == tokenUnicID
            }) else {
                break
            }
            let wallet = availableServices.remove(at: index)
            availableServices.insert(wallet, at: newIndex)
        }
        
        return availableServices.compactMap { $0 as? T }
    }
}
