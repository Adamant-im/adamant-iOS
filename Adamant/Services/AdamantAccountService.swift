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
	private(set) var loggedAccount: Account?
	private(set) var keypair: Keypair?
	
	private var loginViewController: UIViewController? = nil
	private var storyboardAuthorizationFinishedCallbacks: [(() -> Void)]?
	
	
	// MARK: - Initialization
	init(apiService: ApiService, adamantCore: AdamantCore, dialogService: DialogService, router: Router) {
		self.apiService = apiService
		self.core = adamantCore
		self.dialogService = dialogService
		self.router = router
	}
	
	
	// MARK: Login&Logout functions
	
	func login(passphrase: String, loginCompletionHandler: ((Bool, Account?, Error?) -> Void)?) {
		DispatchQueue.global(qos: .userInitiated).async {
			self.apiService.getAccount(byPassphrase: passphrase) { (account, error) in
				if let account = account {
					self.loggedAccount = account
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
					loginCompletionHandler?(true, account, error)
				} else {
					loginCompletionHandler?(false, nil, error)
				}
			}
		}
	}
	
	func logout() {
		let wasLogged = loggedAccount != nil
		loggedAccount = nil
		keypair = nil
		
		if wasLogged {
			NotificationCenter.default.post(name: Notification.Name.adamantUserLoggedOut, object: nil)
		}
	}
}


// MARK: - AccountService
extension AdamantAccountService {
	func logoutAndPresentLoginStoryboard(animated: Bool, authorizationFinishedHandler: (() -> Void)?) {
		logout()
		
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
