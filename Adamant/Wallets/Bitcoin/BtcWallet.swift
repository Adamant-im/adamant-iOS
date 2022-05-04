//
//  BtcWallet.swift
//  Adamant
//
//  Created by Anton Boyarkin on 14/01/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import Foundation
import BitcoinKit

class BtcWallet: WalletAccount {
    var address: String
    let keystore: HDWallet
    
    var balance: Decimal = 0.0
    var notifications: Int = 0
    
    init(address: String, keystore: HDWallet) {
        self.address = address
        self.keystore = keystore
    }
}
