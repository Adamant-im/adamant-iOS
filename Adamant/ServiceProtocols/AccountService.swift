//
//  AccountService.swift
//  Adamant
//
//  Created by Anokhov Pavel on 07.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

extension Notification.Name {
	/// Raised when user has logged out.
	static let adamantUserLoggedOut = Notification.Name("adamantUserHasLoggedOut")
	
	/// Raised when user has successfully logged in. See AdamantUserInfoKey.AccountService
	static let adamantUserLoggedIn = Notification.Name("adamantUserHasLoggedIn")
	
	// Raised on account info (balance) updated.
	static let adamantAccountDataUpdated = Notification.Name("adamantAccountDataUpdated")
}


/// - loggedAccountAddress: Newly logged account's address
extension AdamantUserInfoKey {
	struct AccountService {
		static let loggedAccountAddress = "adamant.accountService.loggedin.address"
		
		private init() {}
	}
}

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

enum AccountServiceError {
	case userNotLogged
	case invalidPassphrase
	case wrongPassphrase
	case apiError(error: ApiServiceError)
	case internalError(message: String, error: Error?)
	
	var localized: String {
		switch self {
		case .userNotLogged:
			return NSLocalizedString("User not logged!", comment: "Login: user not logged error")
			
		case .invalidPassphrase:
			return NSLocalizedString("Wrong passphrase!", comment: "Login: user typed in wrong passphrase")
			
		case .wrongPassphrase:
			return NSLocalizedString("Wrong passphrase!", comment: "Login: user typed in wrong passphrase")
			
		case .apiError(let error):
			return error.localized
			
		case .internalError(let message, _):
			return String.localizedStringWithFormat(NSLocalizedString("Internal error: %@, report this as a bug", comment: "ApiService: Bad internal application error, report a bug"), message)
		}
	}
}

enum AuthorizeOptions {
	case pin(String)
	case touchId
	case faceId
}


// MARK: - Protocol
protocol AccountService {
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
