//
//  ERC20Wallet.swift
//  Adamant
//
//  Created by Anton Boyarkin on 26/06/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import CommonKit
import Foundation
import Web3Core
import web3swift

final class ERC20Wallet: WalletAccount, @unchecked Sendable {
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
