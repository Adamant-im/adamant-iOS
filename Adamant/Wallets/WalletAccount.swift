//
//  WalletAccount.swift
//  Adamant
//
//  Created by Anokhov Pavel on 03.08.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

// MARK: - Wallet Account
protocol WalletAccount {
    // MARK: Account
    var address: String { get }
    var balance: Decimal { get }
    var minBalance: Decimal { get }
    var minAmount: Decimal { get }
    
    var notifications: Int { get }
}
