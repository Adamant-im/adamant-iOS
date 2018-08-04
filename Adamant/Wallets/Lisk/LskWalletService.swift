//
//  LskWalletService.swift
//  Adamant
//
//  Created by Anokhov Pavel on 03.08.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

class LskWalletService: WalletService {
	// MARK: - Constants
	typealias wallet = LskWallet
	let addressRegex = try! NSRegularExpression(pattern: "^([0-9]{2,22})L$", options: [])
	let transactionFee: Decimal = 0.1
	
	
	// MARK: - Properties
	let enabled = true
	
	// MARK: - Logic
	func getAccountInfo(for address: String) -> LskWallet? {
		return nil
	}
	
	// MARK: - Tools
	func validate(address: String) -> AddressValidationResult {
		let value = address.replacingOccurrences(of: "L", with: "")
		
		return addressRegex.perfectMatch(with: value) ? .valid : .invalid
	}
}
