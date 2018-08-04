//
//  Wallet.swift
//  Adamant
//
//  Created by Anokhov Pavel on 03.08.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

// MARK: - Wallet Service
protocol WalletService {
	associatedtype wallet: WalletAccount
	
	var enabled: Bool { get }
	
	// MARK: Accounts
	func getAccountInfo(for address: String) -> wallet?
	
	// MARK: Constants
	var transactionFee: Decimal { get }
	
	// MARK: Tools
	func formatBalance(wallet: wallet, as format: BalanceFormat, includeCurrencySymbol: Bool) -> String
	func validate(address: String) -> AddressValidationResult
}


// MARK: Default Format function
extension WalletService {
	func formatBalance(wallet: wallet, as format: BalanceFormat, includeCurrencySymbol: Bool) -> String {
		if includeCurrencySymbol {
			return "\(format.defaultFormatter.string(from: wallet.balance as NSNumber)!) \(type(of: wallet).currencySymbol)"
		} else {
			return format.defaultFormatter.string(from: wallet.balance as NSNumber)!
		}
	}
}
