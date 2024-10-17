//
//  WalletAccount.swift
//  Adamant
//
//  Created by Anokhov Pavel on 03.08.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

// MARK: - Wallet Account
protocol WalletAccount: Sendable {
    // MARK: Account
    var unicId: String { get }
    var address: String { get }
    var balance: Decimal { get }
    var isBalanceInitialized: Bool { get }
    
    var notifications: Int { get }
}
