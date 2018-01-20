//
//  AdamantAccountService.swift
//  Adamant-ios
//
//  Created by Anokhov Pavel on 07.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import UIKit

private struct Constants {
	static let loginStoryboard = "Login"
	
	private init() {}
}

class AdamantAccountService: AccountService {
	
	// MARK: - Dependencies
	
	let apiService: ApiService
	let core: AdamantCore
	let router: Router
	let dialogService: DialogService
	
	
	// MARK: - Properties
	var autoupdateInterval: TimeInterval = 3.0
	
	var autoupdate: Bool = true {
		didSet {
			if autoupdate {
				start()
			} else {
				stop()
			}
		}
	}
	
	private(set) var status: AccountStatus = .notLogged
	private(set) var account: Account?
	private(set) var keypair: Keypair?
	
	private var loginViewController: UIViewController? = nil
	private var storyboardAuthorizationFinishedCallbacks: [(() -> Void)]?
	private var timer: Timer?
	
	private let updatingDispatchGroup = DispatchGroup()
	
	// MARK: - Initialization
	init(apiService: ApiService, adamantCore: AdamantCore, dialogService: DialogService, router: Router) {
		self.apiService = apiService
		self.core = adamantCore
		self.dialogService = dialogService
		self.router = router
	}
	
	deinit {
		stop()
	}
}


// MARK: - Login&Logout functions
extension AdamantAccountService {
	func login(passphrase: String, loginCompletionHandler: ((Bool, Account?, Error?) -> Void)?) {
		switch status {
		// Is logging in, return
		case .isLoggingIn:
			return
			
		// Logout first
		case .loggedIn:
			logout(stopAutoupdate: false)
			
		// Go login
		case .notLogged:
			break
		}
		
		status = .isLoggingIn
		DispatchQueue.global(qos: .userInitiated).async {
			self.apiService.getAccount(byPassphrase: passphrase) { (account, error) in
				if let account = account {
					self.account = account
					self.keypair = self.core.createKeypairFor(passphrase: passphrase)
					
					NotificationCenter.default.post(name: Notification.Name.adamantUserLoggedIn, object: account)
					
					if let vc = self.loginViewController {
						vc.dismiss(animated: true, completion: nil)
						self.loginViewController = nil
					}
					
					if let callbacks = self.storyboardAuthorizationFinishedCallbacks {
						for	aCallback in callbacks {
							aCallback()
						}
						
						self.storyboardAuthorizationFinishedCallbacks = nil
					}
					
					self.status = .loggedIn
					if self.autoupdate {
						self.start()
					}
					loginCompletionHandler?(true, account, error)
				} else {
					self.status = .notLogged
					loginCompletionHandler?(false, nil, error)
				}
			}
		}
	}
	
	func logout(stopAutoupdate: Bool = true) {
		if stopAutoupdate && autoupdate {
			stop()
		}
		
		let wasLogged = account != nil
		account = nil
		keypair = nil
		status = .notLogged
		
		if wasLogged {
			NotificationCenter.default.post(name: Notification.Name.adamantUserLoggedOut, object: nil)
		}
	}
}

// MARK: - Update
extension AdamantAccountService {
	func start() {
		if !autoupdate { autoupdate = true }
		
		if status != .loggedIn {
			stop()
			return
		}
		
		timer = Timer(timeInterval: autoupdateInterval, repeats: true, block: { _ in
			let timeout = DispatchTime.now() + DispatchTimeInterval.milliseconds(self.autoupdateInterval > 1 ? Int((self.autoupdateInterval - 1.0) * 1000) : 0)
			if self.updatingDispatchGroup.wait(timeout: timeout) == .success {
				self.updateAccountData()
			}
		})
		RunLoop.current.add(timer!, forMode: .commonModes)
		timer!.fire()
	}
	
	func stop() {
		if autoupdate { autoupdate = false }
		
		timer?.invalidate()
		timer = nil
	}
	
	func updateAccountData() {
		guard let loggedAccount = account else {
			stop()
			return
		}
		
		// Enter 1
		updatingDispatchGroup.enter()
		apiService.getAccount(byPublicKey: loggedAccount.publicKey) { (account, error) in
			guard let account = account else {
				// TODO: Show error
				return
			}
			
			var hasChanges = false
			
			if loggedAccount.balance != account.balance { hasChanges = true }
			
			if hasChanges {
				self.account = account
				NotificationCenter.default.post(name: Notification.Name.adamantAccountDataUpdated, object: account)
			}
			
			// Exit 1
			self.updatingDispatchGroup.leave()
		}
	}
}


// MARK: - AccountService
extension AdamantAccountService {
	func logoutAndPresentLoginStoryboard(animated: Bool, authorizationFinishedHandler: (() -> Void)?) {
		logout(stopAutoupdate: false)
		
		if let _ = loginViewController {	// Already presenting view controller. We will add you to a list, and call you back later. Maybe.
			if let aCallback = authorizationFinishedHandler {
				if var callbacks = storyboardAuthorizationFinishedCallbacks {
					callbacks.append(aCallback)
				} else {
					storyboardAuthorizationFinishedCallbacks = [aCallback]
				}
			}
		} else {	// Not presenting. Create and present.
			guard let vc = router.get(story: .Login).instantiateInitialViewController() else {
				fatalError("Failed to get LoginStory")
			}
			
			loginViewController = vc
			dialogService.presentViewController(vc, animated: animated, completion: nil)
			
			if let callback = authorizationFinishedHandler {
				storyboardAuthorizationFinishedCallbacks = [callback]
			}
		}
	}
}
