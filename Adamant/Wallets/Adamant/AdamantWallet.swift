//
//  AdamantWallet.swift
//  Adamant
//
//  Created by Anokhov Pavel on 03.08.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

class AdamantWallet: WalletAccount {
	let address: String
	var balance: Decimal = 0
	var notifications: Int = 0
	
	init(address: String) {
		self.address = address
	}
}
