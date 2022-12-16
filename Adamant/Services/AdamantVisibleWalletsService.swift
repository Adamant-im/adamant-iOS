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
    
    // MARK: Lifecycle
    init() {
        NotificationCenter.default.addObserver(forName: Notification.Name.AdamantAccountService.userLoggedOut, object: nil, queue: nil) { [weak self] _ in
            self?.securedStore.remove(StoreKey.visibleWallets.invisibleWallets)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func addToInvisibleWallets(_ wallet: String) {
        var wallets = getInvisibleWallets()
        wallets.append(wallet)
        setInvisibleWallets(wallets)
    }
    
    func removeFromInvisibleWallets(_ wallet: String) {
        var wallets = getInvisibleWallets()
//        let index = wallets.firstIndex { ws in
//            return ws.tokenContract == wallet.tokenContract && ws.tokenSymbol == wallet.tokenSymbol
//        }
//        guard let index = index else { return }
        guard let index = wallets.firstIndex(of: wallet) else { return }
        wallets.remove(at: index)
        setInvisibleWallets(wallets)
    }
    
    func getInvisibleWallets() -> [String] {
        guard let wallets: [String] = securedStore.get(StoreKey.visibleWallets.invisibleWallets) else {
            print("getInvisibleWallets is empty")
            return []
        }
        print("getInvisibleWallets =", wallets)
        return wallets
    }
    
    private func setInvisibleWallets(_ wallets: [String]) {
        securedStore.set(wallets, for: StoreKey.visibleWallets.invisibleWallets)
    }
}
