//
//  EthWallet.swift
//  Adamant
//
//  Created by Anokhov Pavel on 03.08.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import web3swift

struct EthWallet: WalletAccount {
	let address: String
	let balance: Decimal
	
	let ethAddress: EthereumAddress
}
