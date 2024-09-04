//
//  AdmWallet.swift
//  Adamant
//
//  Created by Anokhov Pavel on 03.08.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

final class AdmWallet: WalletAccount {
    var unicId: String
    let address: String
    var balance: Decimal = 0
    var notifications: Int = 0
    var minBalance: Decimal = 0
    var minAmount: Decimal = 0
    var isBalanceInitialized: Bool = false
    
    init(unicId: String, address: String) {
        self.unicId = unicId
        self.address = address
    }
}
