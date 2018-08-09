//
//  AdamantWalletService.swift
//  Adamant
//
//  Created by Anokhov Pavel on 03.08.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import UIKit

class AdamantWalletService: WalletService {
	static var walletUpdatedNotification = Notification.Name("adm.update")
	static let serviceEnabledChanged = Notification.Name("adm.enabledChanged")
	
	// MARK: - Constants
	let addressRegex = try! NSRegularExpression(pattern: "^U([0-9]{6,20})$", options: [])
	let transactionFee: Decimal = 0.5
	
	static var currencySymbol = "ADM"
	static var currencyLogo = #imageLiteral(resourceName: "wallet_adm")
	
	
	// MARK: - Properties
	let enabled: Bool = true
	
	
	// MARK: - State
	private (set) var state: WalletServiceState = .notInitiated
	private (set) var wallet: WalletAccount? = nil
	
	
	// MARK: - Logic
	func update() {
		
	}
	
	
	// MARK: - Tools
	func validate(address: String) -> AddressValidationResult {
		guard !AdamantContacts.systemAddresses.contains(address) else {
			return .system
		}
		
		return addressRegex.perfectMatch(with: address) ? .valid : .invalid
	}
}
