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
protocol VisibleWalletsService: AnyObject {
    func addToInvisibleWallets(_ wallet: WalletCoreProtocol)
    func removeFromInvisibleWallets(_ wallet: WalletCoreProtocol)
    func getInvisibleWallets() -> [String]
    func isInvisible(_ wallet: WalletCoreProtocol) -> Bool
    
    func getSortedWallets(includeInvisible: Bool) -> [String]
    func setIndexPositionWallets(_ indexes: [String], includeInvisible: Bool)
    func getIndexPosition(for wallet: WalletCoreProtocol) -> Int?
    func setIndexPositionWallets(_ wallets: [WalletCoreProtocol], includeInvisible: Bool)
    
    func reset()
    
    func sorted<T>(includeInvisible: Bool) -> [T]
}
