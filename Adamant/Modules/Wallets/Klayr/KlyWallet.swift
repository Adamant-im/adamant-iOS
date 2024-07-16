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

final class KlyWallet: WalletAccount {
    let legacyAddress: String
    let kly32Address: String
    let keyPair: KeyPair
    var balance: Decimal = 0.0
    var notifications: Int = 0
    var isNewApi: Bool = true
    var nonce: UInt64
    var minBalance: Decimal = 0.05
    var minAmount: Decimal = 0
    var isBalanceInitialized: Bool = false
    
    var address: String {
        return isNewApi ? kly32Address : legacyAddress
    }

    var binaryAddress: String {
        return isNewApi 
        ? LiskKit.Crypto.getBinaryAddressFromBase32(kly32Address) ?? .empty
        : legacyAddress
    }

    init(
        address: String,
        keyPair: KeyPair,
        nonce: UInt64,
        isNewApi: Bool
    ) {
        self.legacyAddress = address
        self.keyPair = keyPair
        self.isNewApi = isNewApi
        self.nonce = nonce
        self.kly32Address = LiskKit.Crypto.getBase32Address(
            from: keyPair.publicKeyString
        )
    }
}
