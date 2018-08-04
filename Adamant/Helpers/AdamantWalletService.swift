//
//  AdamantWalletService.swift
//  Adamant
//
//  Created by Anokhov Pavel on 03.08.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

class AdamantWalletService: WalletService {
	// MARK: - Constants
	typealias wallet = EthWallet
	let addressRegex = try! NSRegularExpression(pattern: "^U([0-9]{6,20})$", options: [])
	let transactionFee: Decimal = 0.5
	
	// MARK: - Properties
	let enabled = true
	
	
	// MARK: - Logic
	func getAccountInfo(for address: String) -> EthWallet? {
		return nil
	}
	
	
	// MARK: - Tools
	func validate(address: String) -> AddressValidationResult {
		guard !AdamantContacts.systemAddresses.contains(address) else {
			return .system
		}
		
		return addressRegex.perfectMatch(with: address) ? .valid : .invalid
	}
}
