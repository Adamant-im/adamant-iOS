//
//  DashWallet.swift
//  Adamant
//
//  Created by Anton Boyarkin on 25/04/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import Foundation
import BitcoinKit

final class DashWallet: WalletAccount {
    var unicId: String
    let addressEntity: Address
    let privateKey: PrivateKey
    let publicKey: PublicKey
    var balance: Decimal = 0.0
    var notifications: Int = 0
    var minBalance: Decimal = 0.0001
    var minAmount: Decimal = 0.00002
    var isBalanceInitialized: Bool = false
    
    var address: String { addressEntity.stringValue }
    
    init(
        unicId: String,
        privateKey: PrivateKey,
        addressConverter: AddressConverter
    ) throws {
        self.unicId = unicId
        self.privateKey = privateKey
        self.publicKey = privateKey.publicKey()
        
        self.addressEntity = try addressConverter.convert(
            publicKey: publicKey,
            type: .p2pkh
        )
    }
}
