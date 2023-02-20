//
//  EthAccount.swift
//  Adamant
//
//  Created by Anokhov Pavel on 02.08.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import web3swift
import struct BigInt.BigUInt
import Web3Core

struct EthAccount {
    let wallet: BIP32Keystore
    let address: String?
    var balance: BigUInt?
    var balanceString: String?
}
