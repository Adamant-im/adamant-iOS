//
//  VisibleWalletsService.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 13.12.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import Foundation

// MARK: - Notifications
extension Notification.Name {
    struct AdamantVisibleWalletsService {
        /// Raised when user has changed visible wallets
        static let visibleWallets = Notification.Name("adamant.visibleWallets.update")
        
    }
}
protocol VisibleWalletsService: AnyObject, Sendable {
    func addToInvisibleWallets(_ walletID: String)
    func removeFromInvisibleWallets(_ walletID: String)
    func getSortedWallets(includeInvisible: Bool) -> [String]
    func isInvisible(_ walletID: String) -> Bool
    
    func setIndexPositionWallets(_ indexes: [String], includeInvisible: Bool)
    
    func reset()
}

//TODO: Think about name
protocol WalletsStoreService: AnyObject {
    func sorted(includeInvisible: Bool) -> [WalletService]
    func isInvisible(_ wallet: WalletService) -> Bool
}

final class AdamantWalletsStoreService: WalletsStoreService {
    let visibleWalletsService: VisibleWalletsService
    let walletsServiceCompose: WalletServiceCompose
    
    init(
        visibleWalletsService: VisibleWalletsService,
        walletsServiceCompose: WalletServiceCompose
    ) {
        self.visibleWalletsService = visibleWalletsService
        self.walletsServiceCompose = walletsServiceCompose
    }
        
    
    func isInvisible(_ wallet: WalletService) -> Bool{
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
        let wallets = walletsServiceCompose.getWallets()
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
