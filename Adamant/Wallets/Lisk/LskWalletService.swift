//
//  LskWalletService.swift
//  Adamant
//
//  Created by Anokhov Pavel on 03.08.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

class LskWalletService: WalletService {
	typealias wallet = LskWallet
	
	// MARK: - Properties
	let enabled = true
	
	// MARK: - Logic
	func getAccountInfo(for address: String) -> LskWallet? {
		return nil
	}
}
