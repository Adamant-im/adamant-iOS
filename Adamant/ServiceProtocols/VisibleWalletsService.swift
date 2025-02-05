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
    func addToInvisibleWallets(_ wallet: String)
    func removeFromInvisibleWallets(_ wallet: String)
    func getInvisibleWallets() -> [String]
    func isInvisible(_ wallet: String) -> Bool
    
    func getSortedWallets(includeInvisible: Bool) -> [String]
    func setIndexPositionWallets(_ indexes: [String], includeInvisible: Bool)
    func getIndexPosition(for wallet: String) -> Int?
    
    func reset()
    
    func sorted(includeInvisible: Bool) -> [WalletService]
}
