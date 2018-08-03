//
//  BalanceFormat.swift
//  Adamant
//
//  Created by Anokhov Pavel on 03.08.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

/// MARK: - Formatters
enum BalanceFormat {
	case full, compact, short
	
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
	
	var defaultFormatter: NumberFormatter {
		switch self {
		case .full: return BalanceFormat.currencyFormatterFull
		case .compact: return BalanceFormat.currencyFormatterCompact
		case .short: return BalanceFormat.currencyFormatterShort
		}
	}
}
