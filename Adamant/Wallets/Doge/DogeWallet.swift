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
    lazy var address: String = {
        return publicKey.toCashaddr().base58
    }()
    let privateKey: PrivateKey
    let publicKey: PublicKey
    var balance: Decimal = 0.0
    var notifications: Int = 0
    var minBalance: Decimal = 0
    var minAmount: Decimal = 0
    
    init(privateKey: PrivateKey) {
        self.privateKey = privateKey
        self.publicKey = privateKey.publicKey()
    }
    
    init(address: String, privateKey: PrivateKey, balance: Decimal, notifications: Int) {
        self.privateKey = privateKey
        self.balance = balance
        self.notifications = notifications
        self.publicKey = privateKey.publicKey()
    }
}
