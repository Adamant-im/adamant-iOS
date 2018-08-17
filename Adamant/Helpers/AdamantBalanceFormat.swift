//
//  AdamantBalanceFormat.swift
//  Adamant
//
//  Created by Anokhov Pavel on 03.08.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

/// MARK: - Formatters
enum AdamantBalanceFormat {
	// MARK: Styles
	
	case full, compact, short
	
	
	// MARK: Formatters
	
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
	
	var defaultFormatter: NumberFormatter {
		switch self {
		case .full: return AdamantBalanceFormat.currencyFormatterFull
		case .compact: return AdamantBalanceFormat.currencyFormatterCompact
		case .short: return AdamantBalanceFormat.currencyFormatterShort
		}
	}
	
	func format(balance: Decimal, withCurrencySymbol symbol: String? = nil) -> String {
		if let symbol = symbol {
			return "\(defaultFormatter.string(from: balance as NSNumber)!) \(symbol)"
		} else {
			return defaultFormatter.string(from: balance as NSNumber)!
		}
	}
}
