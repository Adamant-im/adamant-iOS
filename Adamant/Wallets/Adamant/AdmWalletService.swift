//
//  AdmWalletService.swift
//  Adamant
//
//  Created by Anokhov Pavel on 03.08.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import UIKit
import Swinject
import CoreData

class AdmWalletService: NSObject, WalletService {
	// MARK: - Constants
	let addressRegex = try! NSRegularExpression(pattern: "^U([0-9]{6,20})$")
	
	let transactionFee: Decimal = 0.5
	static var currencySymbol = "ADM"
	static var currencyLogo = #imageLiteral(resourceName: "wallet_adm")
	
	
	// MARK: - Dependencies
	weak var accountService: AccountService!
	var apiService: ApiService!
	var transfersProvider: TransfersProvider!
	var router: Router!
	
	
	// MARK: - Notifications
	let walletUpdatedNotification = Notification.Name("adamant.admWallet.updated")
	let serviceEnabledChanged = Notification.Name("adamant.admWallet.enabledChanged")
	let transactionFeeUpdated: Notification.Name = Notification.Name("adamant.admWallet.feeUpdated")
	
	// MARK: - Properties
	let enabled: Bool = true
	
	var walletViewController: WalletViewController {
		guard let vc = router.get(scene: AdamantScene.Wallets.Adamant.wallet) as? AdmWalletViewController else {
			fatalError("Can't get AdmWalletViewController")
		}
		
		vc.service = self
		return vc
	}
	
	private var transfersController: NSFetchedResultsController<TransferTransaction>?
	
	// MARK: - State
	private (set) var state: WalletServiceState = .notInitiated
	private (set) var wallet: WalletAccount? = nil
	
	
	// MARK: - Logic
	override init() {
		super.init()
		
		// MARK: Notifications
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
		
		let notify: Bool
		if let wallet = wallet as? AdmWallet {
			if wallet.balance != account.balance {
				wallet.balance = account.balance
				notify = true
			} else {
				notify = false
			}
		} else {
			let wallet = AdmWallet(address: account.address)
			wallet.balance = account.balance
			
			self.wallet = wallet
			notify = true
		}
		
		if notify, let wallet = wallet {
			postUpdateNotification(with: wallet)
		}
	}
	
	
	// MARK: - Tools
	func validate(address: String) -> AddressValidationResult {
		guard !AdamantContacts.systemAddresses.contains(address) else {
			return .system
		}
		
		return addressRegex.perfectMatch(with: address) ? .valid : .invalid
	}
	
	private func postUpdateNotification(with wallet: WalletAccount) {
		NotificationCenter.default.post(name: walletUpdatedNotification, object: self, userInfo: [AdamantUserInfoKey.WalletService.wallet: wallet])
	}
}

extension AdmWalletService: WalletServiceWithTransfers {
	func transferListViewController() -> UIViewController {
		return router.get(scene: AdamantScene.Wallets.Adamant.transactionsList)
	}
}


// MARK: - NSFetchedResultsControllerDelegate
extension AdmWalletService: NSFetchedResultsControllerDelegate {
	func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
		guard let newCount = controller.fetchedObjects?.count, let wallet = wallet as? AdmWallet else {
			return
		}
		
		if newCount != wallet.notifications {
			wallet.notifications = newCount
			postUpdateNotification(with: wallet)
		}
	}
}


// MARK: - Dependencies
extension AdmWalletService: SwinjectDependentService {
	func injectDependencies(from container: Container) {
		accountService = container.resolve(AccountService.self)
		apiService = container.resolve(ApiService.self)
		transfersProvider = container.resolve(TransfersProvider.self)
		router = container.resolve(Router.self)
		
		let controller = transfersProvider.unreadTransfersController()
		
		do {
			try controller.performFetch()
		} catch {
			print("AdmWalletService: Error performing fetch: \(error)")
		}
		
		controller.delegate = self
		transfersController = controller
	}
}
