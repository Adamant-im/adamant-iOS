//
//  WalletAccount.swift
//  Adamant
//
//  Created by Anokhov Pavel on 03.08.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import UIKit

// MARK: - Wallet Account
protocol WalletAccount {
	// MARK: Account
	var address: String { get }
	var balance: Decimal { get }
	
	// MARK: Currency
	static var currencySymbol: String { get }
	static var currencyLogo: UIImage { get }
}
