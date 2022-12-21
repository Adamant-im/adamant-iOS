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
    
    // MARK: Lifecycle
    init() {
        NotificationCenter.default.addObserver(forName: Notification.Name.AdamantAccountService.userLoggedOut, object: nil, queue: nil) { [weak self] _ in
            self?.securedStore.remove(StoreKey.visibleWallets.invisibleWallets)
        }
        
        NotificationCenter.default.addObserver(forName: Notification.Name.AdamantAccountService.userLoggedIn, object: nil, queue: nil) { [weak self] _ in
            self?.invisibleWallets = self?.getInvisibleWallets() ?? []
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func addToInvisibleWallets(_ wallet: WalletService) {
        var wallets = getInvisibleWallets()
        wallets.append(wallet.tokenSymbol)
        setInvisibleWallets(wallets)
    }
    
    func removeFromInvisibleWallets(_ wallet: WalletService) {
        var wallets = getInvisibleWallets()
        guard let index = wallets.firstIndex(of: wallet.tokenSymbol) else { return }
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
        return invisibleWallets.contains(wallet.tokenSymbol)
    }
    
    private func setInvisibleWallets(_ wallets: [String]) {
        securedStore.set(wallets, for: StoreKey.visibleWallets.invisibleWallets)
        invisibleWallets = getInvisibleWallets()
    }
}
