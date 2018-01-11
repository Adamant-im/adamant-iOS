//
//  LoginService.swift
//  Adamant-ios
//
//  Created by Anokhov Pavel on 07.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

extension Notification.Name {
	/// Raised, when user has logged out.
	static let userHasLoggedOut = Notification.Name("adamantUserHasLoggedOutNotification")
	
	/// Raised, when user has successfully logged in.
	static let userHasLoggedIn = Notification.Name("adamantUserHasLoggedInNotification")
}

protocol LoginService {
	/// Currently logged account. nil if not logged.
	var loggedAccount: Account? { get }
	
	/// Keypair of logged account
	var keypair: Keypair? { get }
	
	/// Login into Adamant using passphrase.
	///
	/// - Parameters:
	///   - passphrase: Your unique passphrase
	///   - loginCompletionHandler: Completion handler. Success, logged account if success, error if not.
	func login(passphrase: String, loginCompletionHandler: ((Bool, Account?, Error?) -> Void)?)
	
	/// Logout, if logged in, present authorization viewControllers modally. After login or cancel will dismiss modal window and then call a callback.
	///
	/// - Parameters:
	///   - animated: Present modally with or without animation.
	///   - authorizationFinished: callback. Success and error, if present.
	func logoutAndPresentLoginStoryboard(animated: Bool, authorizationFinishedHandler: (() -> Void)?)
}
