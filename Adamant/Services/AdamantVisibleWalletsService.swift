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
    private var invisibleWallets: [String] = []
    private var indexesWallets: [String: Int] = [:]
    
    // MARK: Lifecycle
    init(securedStore: SecuredStore, accountService: AccountService) {
        self.securedStore = securedStore
        self.accountService = accountService
        
        NotificationCenter.default.addObserver(forName: Notification.Name.AdamantAccountService.userLoggedOut, object: nil, queue: nil) { [weak self] _ in
            self?.securedStore.remove(StoreKey.visibleWallets.invisibleWallets)
            self?.securedStore.remove(StoreKey.visibleWallets.indexWallets)
            self?.securedStore.remove(StoreKey.visibleWallets.useCustomIndexes)
            NotificationCenter.default.post(name: Notification.Name.AdamantVisibleWalletsService.visibleWallets, object: nil)
        }
        
        NotificationCenter.default.addObserver(forName: Notification.Name.AdamantAccountService.userLoggedIn, object: nil, queue: nil) { [weak self] _ in
            self?.invisibleWallets = self?.getInvisibleWallets() ?? []
            self?.indexesWallets = self?.getIndexPositionWallets(includeInvisible: false) ?? [:]
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
        guard isUseCustomFilter() else {
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
        securedStore.set(true, for: StoreKey.visibleWallets.useCustomIndexes)
        invisibleWallets = getInvisibleWallets()
    }
    
    // MARK: Index Positions
    
    func getIndexPosition(for wallet: WalletService) -> Int? {
        return indexesWallets[wallet.tokenUnicID]
    }
    
    func getIndexPositionWallets(includeInvisible: Bool) -> [String : Int] {
        guard isUseCustomFilter() else {
            // Sort by default ordinal number
            // Coins without an order are shown last, alphabetically
            let walletsIV = includeInvisible ? accountService.wallets : accountService.wallets.filter { $0.defaultVisibility == true }
            var walletsWithIndexes = walletsIV.filter { $0.defaultOrdinalLevel != nil }.sorted(by: { $0.defaultOrdinalLevel! < $1.defaultOrdinalLevel! })
            let walletsWithNoIndexes = walletsIV.filter { $0.defaultOrdinalLevel == nil }.sorted(by: { $0.tokenName < $1.tokenName })
            
            walletsWithIndexes.append(contentsOf: walletsWithNoIndexes)
            
            var idexes: [String: Int] = [:]
            for (index, wallet) in walletsWithIndexes.enumerated() {
                idexes[wallet.tokenUnicID] = index
            }
            
            return idexes
        }
        
        let path = !includeInvisible ? StoreKey.visibleWallets.indexWallets : StoreKey.visibleWallets.indexWalletsWithInvisible
        guard let indexes: [String: Int] = securedStore.get(path) else {
            return [:]
        }
        return indexes
    }
    
    func editIndexPosition(for wallet: WalletService, index: Int) {
        var indexes = getIndexPositionWallets(includeInvisible: false)
        indexes[wallet.tokenUnicID] = index
        setIndexPositionWallets(indexes, includeInvisible: false)
    }
    
    func setIndexPositionWallets(_ indexes: [String : Int], includeInvisible: Bool) {
        let path = !includeInvisible ? StoreKey.visibleWallets.indexWallets : StoreKey.visibleWallets.indexWalletsWithInvisible
        securedStore.set(indexes, for: path)
        indexesWallets = getIndexPositionWallets(includeInvisible: false)
        securedStore.set(true, for: StoreKey.visibleWallets.useCustomIndexes)
    }
    
    func setIndexPositionWallets(_ wallets: [WalletService], includeInvisible: Bool) {
        var indexes: [String: Int] = [:]
        let wallets = includeInvisible ? wallets : wallets.filter { !isInvisible($0) }
        for (index, wallet) in wallets.enumerated() {
            indexes[wallet.tokenUnicID] = index
        }
        setIndexPositionWallets(indexes, includeInvisible: includeInvisible)
    }
    
    func reset() {
        securedStore.set(false, for: StoreKey.visibleWallets.useCustomIndexes)
        indexesWallets = getIndexPositionWallets(includeInvisible: false)
        invisibleWallets = getInvisibleWallets()
        NotificationCenter.default.post(name: Notification.Name.AdamantVisibleWalletsService.visibleWallets, object: nil)
    }
    
    func isUseCustomFilter() -> Bool {
        let path = StoreKey.visibleWallets.useCustomIndexes
        guard let result: Bool = securedStore.get(path) else {
            return false
        }
        return result
    }
    
    // MARK: - Sort by indexes
    
    func sorted<T>(includeInvisible: Bool) -> [T] {
        var availableServices: [WalletService] = accountService.wallets
        if !includeInvisible {
            availableServices.removeAll()
            for walletService in accountService.wallets where !isInvisible(walletService) {
                availableServices.append(walletService)
            }
        }
        
        // sort manually
        getIndexPositionWallets(includeInvisible: includeInvisible).sorted { $0.value < $1.value }.forEach { tokenUnicID, newIndex in
            guard let index = availableServices.firstIndex(where: { wallet in
                return wallet.tokenUnicID == tokenUnicID
            }) else { return }
            let wallet = availableServices.remove(at: index)
            availableServices.insert(wallet, at: newIndex)
        }
        
        // check if is the <T>
        var arraOfAvailableServices: [T] = []
        availableServices.forEach { wallet in
            if let walletService = wallet as? T {
                arraOfAvailableServices.append(walletService)
            }
        }
        
        return arraOfAvailableServices
    }
}
