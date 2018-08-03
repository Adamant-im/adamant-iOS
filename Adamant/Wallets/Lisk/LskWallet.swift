//
//  LskWallet.swift
//  Adamant
//
//  Created by Anokhov Pavel on 03.08.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import UIKit

struct LskWallet: WalletAccount {
	let address: String
	let balance: Decimal
	
	// MARK: Currency
	static var currencySymbol = "LSK"
	static var currencyLogo = #imageLiteral(resourceName: "wallet_lsk")
}
