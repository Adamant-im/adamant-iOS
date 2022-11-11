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

    var address: String {
        return isNewApi ? lisk32Address : legacyAddress
    }

    var binaryAddress: String {
        return isNewApi ? LiskKit.Crypto.getBinaryAddressFromBase32(lisk32Address) ?? "" : legacyAddress
    }

    let legacyAddress: String
    let lisk32Address: String
    let keyPair: KeyPair
    var balance: Decimal = 0.0
    var notifications: Int = 0
    var isNewApi: Bool = true
    var nounce: String
    var minBalance: Decimal = 0.05
    var minAmount: Decimal = 0
    
    init(address: String, keyPair: KeyPair, nounce: String, isNewApi: Bool) {
        self.legacyAddress = address
        self.keyPair = keyPair
        self.lisk32Address = LiskKit.Crypto.getBase32Address(from: keyPair.publicKeyString)
        self.isNewApi = isNewApi
        self.nounce = nounce
    }

}
