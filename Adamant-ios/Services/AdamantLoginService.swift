//
//  AdamantLoginService.swift
//  Adamant-ios
//
//  Created by Павел Анохов on 07.01.2018.
//  Copyright © 2018 adamant. All rights reserved.
//

import Foundation

class AdamantLoginService: LoginService {
	// MARK: - Dependencies
	let apiService: ApiService
	
	// MARK: - Properties
	var loggedAccount: Account?
	
	// MARK: - Initialization
	init(apiService: ApiService) {
		self.apiService = apiService
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
	func logoutAndPresentLoginStoryboard(animated: Bool, authorizationFinishedHandler: ((Bool, Error?) -> Void)?) {
		logout()
		
		
	}
}
