//
//  AdmWallet.swift
//  Adamant
//
//  Created by Anokhov Pavel on 03.08.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import CommonKit
import Foundation

final class AdmWallet: WalletAccount, @unchecked Sendable {
    let unicId: String
    let address: String

    @Atomic var balance: Decimal = 0
    @Atomic var notifications: Int = 0
    @Atomic var minBalance: Decimal = 0
    @Atomic var minAmount: Decimal = 0
    @Atomic var isBalanceInitialized: Bool = false

    init(unicId: String, address: String) {
        self.unicId = unicId
        self.address = address
    }
}
