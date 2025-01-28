//
//  AdmWallet.swift
//  Adamant
//
//  Created by Anokhov Pavel on 03.08.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import CommonKit

struct AdmWallet: WalletAccount, Sendable {
    let unicId: String
    let address: String
    
    var balance: Decimal = 0
    var notifications: Int = 0
    var minBalance: Decimal = 0
    var minAmount: Decimal = 0
    var isBalanceInitialized: Bool = false
    
    init(unicId: String, address: String, balance: Decimal = 0) {
        self.unicId = unicId
        self.address = address
        self.balance = balance
    }
}
