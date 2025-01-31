//
//  DogeWallet.swift
//  Adamant
//
//  Created by Anton Boyarkin on 05/03/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import Foundation
@preconcurrency import BitcoinKit
import CommonKit

final class DogeWallet: WalletAccount, @unchecked Sendable {
    let unicId: String
    let addressEntity: Address
    let privateKey: PrivateKey
    let publicKey: PublicKey
    
    @Atomic var balance: Decimal = 0.0
    @Atomic var notifications: Int = 0
    @Atomic var minBalance: Decimal = 0
    @Atomic var minAmount: Decimal = 0
    @Atomic var isBalanceInitialized: Bool = false
    
    var address: String { addressEntity.stringValue }
    
    init(
        unicId: String,
        privateKey: PrivateKey,
        addressConverter: AddressConverter
    ) throws {
        self.unicId = unicId
        self.privateKey = privateKey
        self.publicKey = privateKey.publicKey()
        self.addressEntity = try addressConverter.convert(publicKey: publicKey, type: .p2pkh)
    }
    
    init(
        unicId: String,
        privateKey: PrivateKey,
        balance: Decimal,
        notifications: Int,
        addressConverter: AddressConverter
    ) throws {
        self.unicId = unicId
        self.privateKey = privateKey
        self.balance = balance
        self.notifications = notifications
        self.publicKey = privateKey.publicKey()
        self.addressEntity = try addressConverter.convert(publicKey: publicKey, type: .p2pkh)
    }
    
#if DEBUG
    @available(*, deprecated, message: "For testing purposes only")
    init(
        unicId: String,
        privateKey: PrivateKey,
        addressEntity: Address
    ) {
        self.unicId = unicId
        self.privateKey = privateKey
        self.publicKey = privateKey.publicKey()
        self.addressEntity = addressEntity
    }
#endif
}
