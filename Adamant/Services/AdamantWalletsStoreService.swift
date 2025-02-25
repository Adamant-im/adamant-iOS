//
//  AdamantWalletsStoreService.swift
//  Adamant
//
//  Created by Dmitrij Meidus on 08.02.25.
//  Copyright © 2025 Adamant. All rights reserved.
//

struct AdamantWalletStoreService: WalletStoreServiceProtocol {
    let visibleWalletsService: VisibleWalletsService
    let walletServiceCompose: WalletServiceCompose
    
    init(
        visibleWalletsService: VisibleWalletsService,
        walletServiceCompose: WalletServiceCompose
    ) {
        self.visibleWalletsService = visibleWalletsService
        self.walletServiceCompose = walletServiceCompose
    }
        
    func isInvisible(_ wallet: WalletService) -> Bool {
        visibleWalletsService.isInvisible(wallet.core.tokenUniqueID)
    }
    // MARK: - Sort by indexes
    /* How it works:
     1. Get all unsorted wallets
     2. Get the sorted wallets from the database
     3. Shuffle the unsorted wallets (by removing a wallet from the array and inserting it at a certain position).
     We can't use only point 2, because in the future we can add new tokens that won't be in the database
     */
    func sorted(includeInvisible: Bool) -> [WalletService] {
        let wallets = walletServiceCompose.getWallets()
        var availableServices = includeInvisible
        ? wallets
        : wallets.filter { !isInvisible($0) }
        
        for (newIndex, tokenUniqueID) in visibleWalletsService.getSortedWallets(includeInvisible: includeInvisible).enumerated() {
            guard let index = availableServices.firstIndex(
                where: { $0.core.tokenUniqueID == tokenUniqueID }
            ) else {
                continue
            }
            
            let wallet = availableServices.remove(at: index)
            
            if availableServices.indices.contains(newIndex) {
                availableServices.insert(wallet, at: newIndex)
            } else {
                availableServices.append(wallet)
            }
        }
        
        return availableServices
    }
}
