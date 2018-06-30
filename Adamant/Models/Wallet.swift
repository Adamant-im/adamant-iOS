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
	case etherium(balance: Decimal)
	
	var currencyLogo: UIImage {
		switch self {
		case .adamant: return UIImage()
		case .etherium: return UIImage()
		}
	}
	
	var currencySymbol: String {
		switch self {
		case .adamant: return "ADM"
		case .etherium: return "ETH"
		}
	}
}
