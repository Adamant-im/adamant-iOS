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
	static var currencyFormatter: NumberFormatter = {
		let formatter = NumberFormatter()
		formatter.numberStyle = .decimal
		formatter.roundingMode = .floor
		formatter.positiveFormat = "#.########"
		return formatter
	}()
	
	var formattedShort: String? {
		switch self {
		case .adamant(let balance): //, .ethereum(let balance):
			return Wallet.currencyFormatter.string(from: balance as NSNumber)!
			
		case .ethereum:
			return nil
		}
	}
	
	var formattedFull: String? {
		switch self {
		case .adamant(let balance): //, .ethereum(let balance):
			return "\(Wallet.currencyFormatter.string(from: balance as NSNumber)!) \(currencySymbol)"
			
		case .ethereum:
			return nil
		}
	}
}
