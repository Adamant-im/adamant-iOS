//
//  AdamantWallet.swift
//  Adamant
//
//  Created by Anokhov Pavel on 03.08.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

struct AdamantWallet: WalletAccount {
	let address: String
	let balance: Decimal
	
	func formatBalance(format: BalanceFormat, includeCurrencySymbol: Bool) -> String {
		if includeCurrencySymbol {
			return "\(format.defaultFormatter.string(from: balance as NSNumber)!) \(LskWalletService.currencySymbol)"
		} else {
			return format.defaultFormatter.string(from: balance as NSNumber)!
		}
	}
}
