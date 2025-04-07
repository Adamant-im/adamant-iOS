//
//  EthAccount.swift
//  Adamant
//
//  Created by Anokhov Pavel on 02.08.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import Web3Core
import web3swift

import struct BigInt.BigUInt

struct EthAccount {
    let wallet: BIP32Keystore
    let address: String?
    var balance: BigUInt?
    var balanceString: String?
}
