//
//  LskWallet.swift
//  Adamant
//
//  Created by Anokhov Pavel on 03.08.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import LiskKit

class LskWallet: WalletAccount {
    let address: String
    let keyPair: KeyPair
    var balance: Decimal = 0.0
    var notifications: Int = 0
    
    init(address: String, keyPair: KeyPair) {
        self.address = address
        self.keyPair = keyPair
    }
}
