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
    lazy var address: String = {
        return publicKey.toCashaddr().base58
    }()
    let privateKey: PrivateKey
    lazy var publicKey: PublicKey = {
        return privateKey.publicKey()
    }()
    var balance: Decimal = 0.0
    var notifications: Int = 0
    var minBalance: Decimal = 0
    
    init(privateKey: PrivateKey) {
        self.privateKey = privateKey
    }

}
