//
//  KlyWallet.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 08.07.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import Foundation
import CommonKit
import LiskKit

final class KlyWallet: WalletAccount, @unchecked Sendable {
    let unicId: String
    let legacyAddress: String
    let kly32Address: String
    let keyPair: KeyPair
    
    @Atomic var balance: Decimal = 0.0
    @Atomic var notifications: Int = 0
    @Atomic var isNewApi: Bool = true
    @Atomic var nonce: UInt64
    @Atomic var minBalance: Decimal = 0.05
    @Atomic var minAmount: Decimal = 0
    @Atomic var isBalanceInitialized: Bool = false
    
    var address: String {
        return isNewApi ? kly32Address : legacyAddress
    }

    var binaryAddress: String {
        return isNewApi 
        ? LiskKit.Crypto.getBinaryAddressFromBase32(kly32Address) ?? .empty
        : legacyAddress
    }

    init(
        unicId: String,
        address: String,
        keyPair: KeyPair,
        nonce: UInt64,
        isNewApi: Bool
    ) {
        self.unicId = unicId
        self.legacyAddress = address
        self.keyPair = keyPair
        self.isNewApi = isNewApi
        self.nonce = nonce
        self.kly32Address = LiskKit.Crypto.getBase32Address(
            from: keyPair.publicKeyString
        )
    }
}
