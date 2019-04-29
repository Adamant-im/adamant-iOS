//
//  DogeWallet.swift
//  Adamant
//
//  Created by Anton Boyarkin on 05/03/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import Foundation
import BitcoinKit

class DogeWallet: WalletAccount {
    let address: String
    let privateKey: PrivateKey
    let publicKey: PublicKey
    var balance: Decimal = 0.0
    var notifications: Int = 0
    
    init(privateKey: PrivateKey) {
        self.privateKey = privateKey
        self.publicKey = privateKey.publicKey()
        self.address = publicKey.toCashaddr().base58
    }
    
    init(address: String, privateKey: PrivateKey, balance: Decimal, notifications: Int) {
        self.address = address
        self.privateKey = privateKey
        self.publicKey = privateKey.publicKey()
        self.balance = balance
        self.notifications = notifications
    }
}
