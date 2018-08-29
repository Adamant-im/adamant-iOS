//
//  AdamantBalanceFormat.swift
//  Adamant
//
//  Created by Anokhov Pavel on 03.08.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

// MARK: - Formatters

/// - full: 8 digits after the decimal point
/// - compact: 4 digits after the decimal point
/// - short: 2 digits after the decimal point
enum AdamantBalanceFormat {
	// MARK: Styles
	/// 8 digits after the decimal point
	case full
	
	/// 4 digits after the decimal point
	case compact
	
	/// 2 digits after the decimal point
	case short
	
	
	// MARK: Formatters
	
	static func currencyFormatter(format: AdamantBalanceFormat, currencySymbol symbol: String?) -> NumberFormatter {
		let formatter = NumberFormatter()
		formatter.numberStyle = .decimal
		formatter.roundingMode = .floor
		
		let positiveFormat: String
		
		switch format {
		case .full: positiveFormat = "#.########"
		case .compact: positiveFormat = "#.####"
		case .short: positiveFormat = "#.##"
		}
		
		if let symbol = symbol {
			formatter.positiveFormat = "\(positiveFormat) \(symbol)"
		} else {
			formatter.positiveFormat = positiveFormat
		}
		
		return formatter
	}
	
	static var currencyFormatterFull: NumberFormatter = {
		return currencyFormatter(format: .full, currencySymbol: nil)
	}()
	
	static var currencyFormatterCompact: NumberFormatter = {
		return currencyFormatter(format: .compact, currencySymbol: nil)
	}()
	
	static var currencyFormatterShort: NumberFormatter = {
		return currencyFormatter(format: .short, currencySymbol: nil)
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
