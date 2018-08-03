//
//  EthWallet.swift
//  Adamant
//
//  Created by Anokhov Pavel on 03.08.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import UIKit

struct EthWallet: WalletAccount {
	let address: String
	let balance: Decimal
	
	// MARK: Currency
	static var currencySymbol = "ETH"
	static var currencyLogo = #imageLiteral(resourceName: "wallet_eth")
}
