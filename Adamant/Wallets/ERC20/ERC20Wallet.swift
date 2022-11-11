//
//  ERC20Wallet.swift
//  Adamant
//
//  Created by Anton Boyarkin on 26/06/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import Foundation
import web3swift

class ERC20Wallet: WalletAccount {
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
