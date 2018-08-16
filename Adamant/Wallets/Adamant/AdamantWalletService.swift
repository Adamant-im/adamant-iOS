//
//  AdamantWalletService.swift
//  Adamant
//
//  Created by Anokhov Pavel on 03.08.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import UIKit
import Swinject

class AdamantWalletService: WalletService {
	// MARK: - Constants
	let addressRegex = try! NSRegularExpression(pattern: "^U([0-9]{6,20})$", options: [])
	
	let transactionFee: Decimal = 0.5
	static var currencySymbol = "ADM"
	static var currencyLogo = #imageLiteral(resourceName: "wallet_adm")
	
	
	// MARK: - Dependencies
	weak var accountService: AccountService!
	var router: Router!
	
	
	// MARK: - Notifications
	static var walletUpdatedNotification = Notification.Name("adm.update")
	static let serviceEnabledChanged = Notification.Name("adm.enabledChanged")
	
	
	// MARK: - Properties
	let enabled: Bool = true
	
	var walletViewController: WalletViewController {
		guard let vc = router.get(scene: AdamantScene.Wallets.AdamantWallet) as? AdamantWalletViewController else {
			fatalError("Can't get AdamantWalletViewController")
		}
		
		vc.service = self
		return vc
	}
	
	// MARK: - State
	private (set) var state: WalletServiceState = .notInitiated
	private (set) var wallet: WalletAccount? = nil
	
	
	// MARK: - Logic
	init() {
		NotificationCenter.default.addObserver(forName: Notification.Name.AdamantAccountService.userLoggedIn, object: nil, queue: nil) { [weak self] _ in
			self?.update()
		}
		
		NotificationCenter.default.addObserver(forName: Notification.Name.AdamantAccountService.accountDataUpdated, object: nil, queue: nil) { [weak self] _ in
			self?.update()
		}
		
		NotificationCenter.default.addObserver(forName: Notification.Name.AdamantAccountService.userLoggedOut, object: nil, queue: nil) { [weak self] _ in
			self?.wallet = nil
		}
	}
	
	func update() {
		guard let account = accountService.account else {
			wallet = nil
			return
		}
		
		let newWallet: WalletAccount?
		
		if let wallet = wallet {
			if wallet.balance != account.balance {
				newWallet = AdamantWallet(address: account.address, balance: account.balance)
				self.wallet = newWallet
			} else {
				newWallet = nil
			}
		} else {
			newWallet = AdamantWallet(address: account.address, balance: account.balance)
			self.wallet = newWallet
		}
		
		if let newWallet = newWallet {
			NotificationCenter.default.post(name: AdamantWalletService.walletUpdatedNotification, object: self, userInfo: [AdamantUserInfoKey.WalletService.wallet: newWallet])
		}
	}
	
	
	// MARK: - Tools
	func validate(address: String) -> AddressValidationResult {
		guard !AdamantContacts.systemAddresses.contains(address) else {
			return .system
		}
		
		return addressRegex.perfectMatch(with: address) ? .valid : .invalid
	}
}

extension AdamantWalletService: WalletWithTransfers {
	func transferListViewController() -> UIViewController {
		return router.get(scene: AdamantScene.Transactions.transactions)
	}
}


// MARK: - Dependencies
extension AdamantWalletService: SwinjectDependentService {
	func injectDependencies(from container: Container) {
		accountService = container.resolve(AccountService.self)
		router = container.resolve(Router.self)
	}
}
