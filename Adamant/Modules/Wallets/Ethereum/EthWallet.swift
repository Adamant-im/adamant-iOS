//
//  EthWallet.swift
//  Adamant
//
//  Created by Anokhov Pavel on 03.08.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import web3swift
import CommonKit
@preconcurrency import Web3Core

final class EthWallet: WalletAccount, @unchecked Sendable {
    let unicId: String
    let address: String
    let ethAddress: EthereumAddress
    let keystore: BIP32Keystore
    
    @Atomic var balance: Decimal = 0
    @Atomic var notifications: Int = 0
    @Atomic var minBalance: Decimal = 0
    @Atomic var minAmount: Decimal = 0
    @Atomic var isBalanceInitialized: Bool = false
    
    init(
        unicId: String,
        address: String,
        ethAddress: EthereumAddress,
        keystore: BIP32Keystore
    ) {
        self.unicId = unicId
        self.address = address
        self.ethAddress = ethAddress
        self.keystore = keystore
    }
}
