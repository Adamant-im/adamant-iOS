//
//  AdamantLoginService.swift
//  Adamant-ios
//
//  Created by Павел Анохов on 07.01.2018.
//  Copyright © 2018 adamant. All rights reserved.
//

import Foundation
import UIKit

class AdamantLoginService: LoginService {
	private struct Constants {
		static let loginStoryboard = "Login"
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
	
	func login(passphrase: String) {
		
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
