//
//  Wallet.swift
//  Adamant
//
//  Created by Anokhov Pavel on 29.06.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit

enum Wallet {
	case adamant(balance: Decimal)
	case ethereum
	
	var enabled: Bool {
		switch self {
		case .adamant: return true
		case .ethereum: return false
		}
	}
}


// MARK: - Resources
extension Wallet {
	var currencyLogo: UIImage {
		switch self {
		case .adamant: return #imageLiteral(resourceName: "wallet_adm")
		case .ethereum: return #imageLiteral(resourceName: "wallet_eth")
		}
	}
	
	var currencySymbol: String {
		switch self {
		case .adamant: return "ADM"
		case .ethereum: return "ETH"
		}
	}
}

// MARK: - Formatter
extension Wallet {
	
	// MARK: Formatters
	
	/// Number formatters
	/// - full: 8 decimal digits
	/// - compact: 4 decimal digits
	/// - short: 2 decimal digits
	enum NumberFormat {
		case full, compact, short
		
		var formatter: NumberFormatter {
			switch self {
			case .short: return Wallet.currencyFormatterShort
			case .compact: return Wallet.currencyFormatterCompact
			case .full: return Wallet.currencyFormatterFull
			}
		}
	}
	
	static var currencyFormatterFull: NumberFormatter = {
		let formatter = NumberFormatter()
		formatter.numberStyle = .decimal
		formatter.roundingMode = .floor
		formatter.positiveFormat = "#.########"
		return formatter
	}()
	
	static var currencyFormatterCompact: NumberFormatter = {
		let formatter = NumberFormatter()
		formatter.numberStyle = .decimal
		formatter.roundingMode = .floor
		formatter.positiveFormat = "#.####"
		return formatter
	}()
	
	static var currencyFormatterShort: NumberFormatter = {
		let formatter = NumberFormatter()
		formatter.numberStyle = .decimal
		formatter.roundingMode = .floor
		formatter.positiveFormat = "#.##"
		return formatter
	}()
	
	
	// MARK: Methods
	
	func format(numberFormat: NumberFormat, includeCurrencySymbol: Bool) -> String {
		let balance: String
		switch self {
		case .adamant(let b):
			balance = numberFormat.formatter.string(from: b as NSNumber)!
			
		case .ethereum:
			balance = ""
		}
		
		if includeCurrencySymbol {
			return "\(balance) \(currencySymbol)"
		} else {
			return balance
		}
	}
}
