//
//  AccountService.swift
//  Adamant-ios
//
//  Created by Anokhov Pavel on 07.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

extension Notification.Name {
	/// Raised when user has logged out.
	static let adamantUserLoggedOut = Notification.Name("adamantUserHasLoggedOut")
	
	/// Raised when user has successfully logged in.
	static let adamantUserLoggedIn = Notification.Name("adamantUserHasLoggedIn")
	
	// Raised on account info (balance) updated.
	static let adamantAccountDataUpdated = Notification.Name("adamantAccountDataUpdated")
}

enum AccountStatus {
	case notLogged, isLoggingIn, loggedIn
}

protocol AccountService {
	
	// MARK: - Status
	
	var status: AccountStatus { get }
	var autoupdate: Bool { get set }
	/// Default = 5 seconds
	var autoupdateInterval: TimeInterval { get set }
	
	
	// MARK: - Personal information
	
	/// Currently logged account. nil if not logged.
	var account: Account? { get }
	
	/// Keypair of logged account
	var keypair: Keypair? { get }
	
	
	// MARK: - Update functions
	
	func updateAccountData()
	
	
	// MARK: - Login functions
	
	/// Create new account and login using new passphrase.
	///
	/// - Parameters:
	///   - passphrase: Your new unique passphrase
	///   - completionHandler: New logged account, if success, error if not.
	func createAccount(with passphrase: String, completionHandler: ((Account?, Error?) -> Void)?)
	
	/// Login into Adamant using passphrase.
	///
	/// - Parameters:
	///   - passphrase: Your unique passphrase
	///   - loginCompletionHandler: Logged account if success, error if not.
	func login(with passphrase: String, completionHandler: ((Account?, Error?) -> Void)?)
	
	/// Logout (if logged in) and present authorization viewControllers modally. After login or cancel will dismiss modal window and then call a callback.
	///
	/// - Parameters:
	///   - animated: Present modally with or without animation.
	///   - authorizationFinished: callback. Success and error, if present.
	func logoutAndPresentLoginStoryboard(animated: Bool, authorizationFinishedHandler: (() -> Void)?)
}
