//
//  LskWalletService.swift
//  Adamant
//
//  Created by Anokhov Pavel on 03.08.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import UIKit

class LskWalletService: WalletService {
	var walletViewController: WalletViewController { fatalError() }
	
	static var walletUpdatedNotification = Notification.Name("lsk.update")
	static let serviceEnabledChanged = Notification.Name("lsk.enabledChanged")
	
	// MARK: - Constants
	let addressRegex = try! NSRegularExpression(pattern: "^([0-9]{2,22})L$", options: [])
	let transactionFee: Decimal = 0.1
	let enabled: Bool = true
	
	static var currencySymbol = "LSK"
	static var currencyLogo = #imageLiteral(resourceName: "wallet_lsk")
	
	
	// MARK: - Properties
	let transferAvailable: Bool = true
	
	
	// MARK: - State
	private (set) var state: WalletServiceState = .notInitiated
	private (set) var wallet: WalletAccount? = nil
	
	
	// MARK: - Logic
	func update() {
		
	}
	
	
	// MARK: - Tools
	func validate(address: String) -> AddressValidationResult {
		let value = address.replacingOccurrences(of: "L", with: "")
		
		return addressRegex.perfectMatch(with: value) ? .valid : .invalid
	}
}
