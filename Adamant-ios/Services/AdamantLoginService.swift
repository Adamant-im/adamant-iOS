//
//  AdamantLoginService.swift
//  Adamant-ios
//
//  Created by Anokhov Pavel on 07.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import UIKit

class AdamantLoginService: LoginService {
	private struct Constants {
		static let loginStoryboard = "Login"
		
		private init() {}
	}
	
	// MARK: - Dependencies
	let apiService: ApiService
	let dialogService: DialogService
	
	// MARK: - Properties
	var loggedAccount: Account?
	
	private var loginRootViewController: UIViewController? = nil
	private var storyboardAuthorizationFinishedCallbacks: [(() -> Void)]?
	
	// MARK: - Initialization
	init(apiService: ApiService, dialogService: DialogService) {
		self.apiService = apiService
		self.dialogService = dialogService
	}
	
	
	// MARK: Login&Logout functions
	
	func login(passphrase: String, loginCompletionHandler: ((Bool, Account?, Error?) -> Void)?) {
		DispatchQueue.global(qos: .userInitiated).async {
			self.apiService.getAccount(byPassphrase: passphrase) { (account, error) in
				if let account = account {
					self.loggedAccount = account
					NotificationCenter.default.post(name: Notification.Name.userHasLoggedIn, object: account)
					
					if let vc = self.loginRootViewController {
						vc.dismiss(animated: true, completion: nil)
						self.loginRootViewController = nil
					}
					
					if let callbacks = self.storyboardAuthorizationFinishedCallbacks {
						for	aCallback in callbacks {
							aCallback()
						}
						
						self.storyboardAuthorizationFinishedCallbacks = nil
					}
				}
			}
		}
	}
	
	func logout() {
		if loggedAccount != nil {
			NotificationCenter.default.post(name: Notification.Name.userHasLoggedOut, object: nil)
			loggedAccount = nil
		}
	}
}


// MARK: - LoginService
extension AdamantLoginService {
	func logoutAndPresentLoginStoryboard(animated: Bool, authorizationFinishedHandler: (() -> Void)?) {
		logout()
		
		if let _ = loginRootViewController {	// Already presenting view controller. We will add you to a list, and call you back later. Maybe.
			if let aCallback = authorizationFinishedHandler {
				if var callbacks = storyboardAuthorizationFinishedCallbacks {
					callbacks.append(aCallback)
				} else {
					storyboardAuthorizationFinishedCallbacks = [aCallback]
				}
			}
		} else {	// Not presenting. Create and present.
			loginRootViewController = dialogService.presentStoryboard(Constants.loginStoryboard, viewControllerIdentifier: nil, animated: animated, completion: nil)
			
			if let callback = authorizationFinishedHandler {
				storyboardAuthorizationFinishedCallbacks = [callback]
			}
		}
	}
}
