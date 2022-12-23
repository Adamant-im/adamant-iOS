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
    var securedStore: SecuredStore!
    
    // MARK: Proprieties
    private var invisibleWallets: [String] = []
    private var indexesWallets: [String: Int] = [:]
    
    // MARK: Lifecycle
    init() {
        NotificationCenter.default.addObserver(forName: Notification.Name.AdamantAccountService.userLoggedOut, object: nil, queue: nil) { [weak self] _ in
            self?.securedStore.remove(StoreKey.visibleWallets.invisibleWallets)
            self?.securedStore.remove(StoreKey.visibleWallets.indexWallets)
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
        invisibleWallets = getInvisibleWallets()
    }
    
    // MARK: Index Positions
    
    func getIndexPosition(for wallet: WalletService) -> Int? {
        return indexesWallets[wallet.tokenUnicID]
    }
    
    func getIndexPositionWallets(includeInvisible: Bool) -> [String : Int] {
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
    }
    
    func setIndexPositionWallets(_ wallets: [WalletService], includeInvisible: Bool) {
        var indexes: [String: Int] = [:]
        let wallets = includeInvisible ? wallets : wallets.filter { !isInvisible($0) }
        for (index, wallet) in wallets.enumerated() {
            indexes[wallet.tokenUnicID] = index
        }
        setIndexPositionWallets(indexes, includeInvisible: includeInvisible)
    }
}
