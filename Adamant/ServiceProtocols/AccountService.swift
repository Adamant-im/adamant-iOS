//
//  AccountService.swift
//  Adamant
//
//  Created by Anokhov Pavel on 07.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

// MARK: - Notifications
extension Notification.Name {
	struct AdamantAccountService {
		/// Raised when user has logged out.
		static let userLoggedOut = Notification.Name("adamant.accountService.userHasLoggedOut")
		
		/// Raised when user has successfully logged in. See AdamantUserInfoKey.AccountService
		static let userLoggedIn = Notification.Name("adamant.accountService.userHasLoggedIn")
		
		/// Raised on account info (balance) updated.
		static let accountDataUpdated = Notification.Name("adamant.accountService.accountDataUpdated")
		
		/// Raised when user changed Stay In option.
		///
		/// UserInfo:
		/// - Adamant.AccountService.newStayInState with new state
		static let stayInChanged = Notification.Name("adamant.accountService.stayInChanged")
		
		private init() {}
	}
}


/// - loggedAccountAddress: Newly logged account's address
extension AdamantUserInfoKey {
	struct AccountService {
		static let loggedAccountAddress = "adamant.accountService.loggedin.address"
		static let newStayInState = "adamant.accountService.stayIn"
		
		private init() {}
	}
}

// MARK: - Other const

/// - notLogged: Not logged, empty
/// - isLoggingIn: Is currently trying to log in
/// - loggedIn: Logged in and idling
/// - updating: Is logged in and updating account info
enum AccountServiceState {
	case notLogged, isLoggingIn, loggedIn, updating
}

enum AccountServiceResult {
	case success(account: Account)
	case failure(AccountServiceError)
}

enum AccountServiceError: Error {
	case userNotLogged
	case invalidPassphrase
	case wrongPassphrase
	case apiError(error: ApiServiceError)
	case internalError(message: String, error: Error?)
	
	var localized: String {
		switch self {
		case .userNotLogged:
			return NSLocalizedString("AccountServiceError.UserNotLogged", comment: "Login: user not logged error")
			
		case .invalidPassphrase:
			return NSLocalizedString("AccountServiceError.InvalidPassphrase", comment: "Login: user typed in invalid passphrase")
			
		case .wrongPassphrase:
			return NSLocalizedString("AccountServiceError.WrongPassphrase", comment: "Login: user typed in wrong passphrase")
			
		case .apiError(let error):
			return error.localized
			
		case .internalError(let message, _):
			return String.localizedStringWithFormat(NSLocalizedString("AccountServiceError.InternalErrorFormat", comment: "ApiService: Bad internal application error, report a bug. Using %@ as error description"), message)
		}
	}
}


// MARK: - Protocol
protocol AccountService: class {
	// MARK: State
	
	var state: AccountServiceState { get }
	var account: Account? { get }
	var keypair: Keypair? { get }
	
	
	// MARK: Account functions
	
	/// Update logged account info
	func update()
	
	/// Create new account with passphrase.
	func createAccountWith(passphrase: String, completion: @escaping (AccountServiceResult) -> Void)
	
	/// Login into Adamant using passphrase.
	func loginWith(passphrase: String, completion: @escaping (AccountServiceResult) -> Void)
	
	
	/// Login into Adamant using previously logged account
	func loginWithStoredAccount(completion: @escaping (AccountServiceResult) -> Void)
	
	/// Logout
	func logout()
	
	
	// MARK: Stay in functions
	
	/// There is a stored account information in secured store
	var hasStayInAccount: Bool { get }
	
	/// Use TouchID or FaceID to log in
	var useBiometry: Bool { get set }
	
	
	/// Save account data and use pincode to login
	///
	/// - Parameters:
	///   - pin: pincode to login
	///   - completion: completion handler
	func setStayLoggedIn(pin: String, completion: @escaping (AccountServiceResult) -> Void)
	
	
	/// Remove stored data
	func dropSavedAccount()
	
	/// If we have stored data with pin, validate it. If no data saved, always returns false.
	func validatePin(_ pin: String) -> Bool
}
