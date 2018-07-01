//
//  Wallet.swift
//  Adamant
//
//  Created by Anokhov Pavel on 29.06.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit

enum Wallet {
	static var currencyFormatter: NumberFormatter = {
		let formatter = NumberFormatter()
		formatter.numberStyle = .decimal
		formatter.roundingMode = .floor
		formatter.positiveFormat = "#.########"
		return formatter
	}()
	
	static func format(balance: Decimal) -> String {
		return currencyFormatter.string(from: balance as NSNumber)!
	}
	
	case adamant(balance: Decimal)
	case etherium(balance: Decimal)
	
	var currencyLogo: UIImage {
		switch self {
		case .adamant: return #imageLiteral(resourceName: "wallet_adm")
		case .etherium: return #imageLiteral(resourceName: "wallet_eth")
		}
	}
	
	var currencySymbol: String {
		switch self {
		case .adamant: return "ADM"
		case .etherium: return "ETH"
		}
	}
	
	var fomattedShort: String {
		switch self {
		case .adamant(let balance), .etherium(let balance):
			return Wallet.currencyFormatter.string(from: balance as NSNumber)!
		}
	}
	
	var fomattedFull: String {
		switch self {
		case .adamant(let balance), .etherium(let balance):
			return "\(Wallet.currencyFormatter.string(from: balance as NSNumber)!) \(currencySymbol)"
		}
	}
}
