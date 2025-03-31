//
//  LskAccount.swift
//  Adamant
//
//  Created by Anokhov Pavel on 03.08.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import BigInt
import Foundation
import LiskKit

struct LskAccount {
    let keys: KeyPair
    let address: String
    var balance: BigUInt?
    var balanceString: String?
}
