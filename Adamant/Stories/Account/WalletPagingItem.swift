//
//  WalletPagingItem.swift
//  Adamant
//
//  Created by Anokhov Pavel on 10.08.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import Parchment

class WalletPagingItem: PagingItem, Hashable, Comparable {
	let index: Int
	let currencySymbol: String
	let currencyImage: UIImage
	
	var balance: Decimal = 0
	var notifications: Int = 0
	
	init(index: Int, currencySymbol symbol: String, currencyImage image: UIImage) {
		self.index = index
		currencySymbol = symbol
		currencyImage = image
	}
	
	// MARK: Hashable, Comparable
	var hashValue: Int {
		return index.hashValue &+ currencySymbol.hashValue
	}
	
	static func < (lhs: WalletPagingItem, rhs: WalletPagingItem) -> Bool {
		return lhs.index < rhs.index
	}
	
	static func == (lhs: WalletPagingItem, rhs: WalletPagingItem) -> Bool {
		return lhs.index == rhs.index &&
				lhs.currencySymbol == rhs.currencySymbol
	}
}
