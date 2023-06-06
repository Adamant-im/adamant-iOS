//
//  DashWallet.swift
//  Adamant
//
//  Created by Anton Boyarkin on 25/04/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import Foundation
import BitcoinKit

class DashWallet: WalletAccount {
    let addressEntity: Address
    let privateKey: PrivateKey
    let publicKey: PublicKey
    var balance: Decimal = 0.0
    var notifications: Int = 0
    var minBalance: Decimal = 0.0001
    var minAmount: Decimal = 0.00002
    var isBalanceInitialized: Bool = false
    
    var address: String { addressEntity.stringValue }
    
    init(privateKey: PrivateKey, addressConverter: AddressConverter) throws {
        self.privateKey = privateKey
        self.publicKey = privateKey.publicKey()
        
        self.addressEntity = try addressConverter.convert(
            publicKey: publicKey,
            type: .p2pkh
        )
    }
}
