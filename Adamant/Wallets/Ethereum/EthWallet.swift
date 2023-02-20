//
//  EthWallet.swift
//  Adamant
//
//  Created by Anokhov Pavel on 03.08.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import web3swift
import Web3Core

class EthWallet: WalletAccount {
    let address: String
    let ethAddress: EthereumAddress
    let keystore: BIP32Keystore
    
    var balance: Decimal = 0
    var notifications: Int = 0
    var minBalance: Decimal = 0
    var minAmount: Decimal = 0
    
    init(address: String, ethAddress: EthereumAddress, keystore: BIP32Keystore) {
        self.address = address
        self.ethAddress = ethAddress
        self.keystore = keystore
    }
}
