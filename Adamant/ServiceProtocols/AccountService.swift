//
//  AccountService.swift
//  Adamant
//
//  Created by Anokhov Pavel on 07.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import CommonKit

// MARK: - Notifications
extension Notification.Name {
    struct AdamantAccountService {
        /// Raised when user has successfully logged in. See AdamantUserInfoKey.AccountService
        static let userLoggedIn = Notification.Name("adamant.accountService.userHasLoggedIn")
        
        /// Raised when user has logged out.
        static let userLoggedOut = Notification.Name("adamant.accountService.userHasLoggedOut")
        
        /// Raised when user is about to log out. Save your data.
        static let userWillLogOut = Notification.Name("adamant.accountService.userWillLogOut")
        
        /// Raised on account info (balance) updated.
        static let accountDataUpdated = Notification.Name("adamant.accountService.accountDataUpdated")
        
        /// Raised on account info (balance) updated.
        static let forceUpdateBalance = Notification.Name("adamant.accountService.forceUpdateBalance")
        
        /// Raised on account info (balance) updated.
        static let forceUpdateAllBalances = Notification.Name("adamant.accountService.forceUpdateAllBalances")
        
        /// Raised when user changed Stay In option.
        ///
        /// UserInfo:
        /// - Adamant.AccountService.newStayInState with new state
        static let stayInChanged = Notification.Name("adamant.accountService.stayInChanged")
        
        /// Raised when wallets collection updated
        ///
        /// UserInfo:
        /// - AdamantUserInfoKey.AccountService.updatedWallet: wallet object
        /// - AdamantUserInfoKey.AccountService.updatedWalletIndex: wallet index in AccountService.wallets collection
        static let walletUpdated = Notification.Name("adamant.accountService.walletUpdated")
        
        private init() {}
    }
}

// MARK: - Localization
extension String.adamant {
    enum accountService {
        static var updateAlertTitleV12: String {
            String.localized("AccountService.update.v12.title", comment: "AccountService: Alert title. Changes in version 1.2")
        }
        static var updateAlertMessageV12: String {
            String.localized("AccountService.update.v12.message", comment: "AccountService: Alert message. Changes in version 1.2, notify user that he needs to relogin to initiate eth & lsk wallets")
        }
        static var reloginToInitiateWallets: String {
            String.localized("AccountService.reloginToInitiateWallets", comment: "AccountService: User must relogin into app to initiate wallets")
        }
    }
}


/// - loggedAccountAddress: Newly logged account's address
extension AdamantUserInfoKey {
    struct AccountService {
        static let loggedAccountAddress = "adamant.accountService.loggedin.address"
        static let newStayInState = "adamant.accountService.stayIn"
        static let updatedWallet = "adamant.accountService.updatedWallet"
        static let updatedWalletIndex = "adamant.accountService.updatedWalletIndex"
        
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
    case success(account: AdamantAccount, alert: (title: String, message: String)?)
    case failure(AccountServiceError)
}

enum AccountServiceError: Error {
    case userNotLogged
    case invalidPassphrase
    case wrongPassphrase
    case codeEntryLimitReached
    case apiError(error: ApiServiceError)
    case internalError(message: String, error: Error?)
    
    var localized: String {
        switch self {
        case .userNotLogged:
            return String.adamant.sharedErrors.userNotLogged
            
        case .invalidPassphrase:
            return .localized("AccountServiceError.InvalidPassphrase", comment: "Login: user typed in invalid passphrase")
            
        case .wrongPassphrase:
            return .localized("AccountServiceError.WrongPassphrase", comment: "Login: user typed in wrong passphrase")
            
        case .codeEntryLimitReached:
            return "codeEntryLimitReached"
            
        case .apiError(let error):
            return error.localizedDescription
        
        case .internalError(let message, _):
            return String.adamant.sharedErrors.internalError(message: message)
        }
    }
}

extension AccountServiceError: RichError {
    var message: String {
        return localized
    }
    
    var internalError: Error? {
        switch self {
        case .apiError(let error as Error?), .internalError(_, let error):
            return error
            
        default:
            return nil
        }
    }
    
    var level: ErrorLevel {
        switch self {
        case .wrongPassphrase, .userNotLogged, .invalidPassphrase, .codeEntryLimitReached:
            return .warning
            
        case .apiError(let error):
            return error.level
            
        case .internalError:
            return .internalError
        }
    }
}

// MARK: - Protocol
protocol AccountService: AnyObject {
    // MARK: State
    
    var state: AccountServiceState { get }
    var account: AdamantAccount? { get }
    var keypair: Keypair? { get }
    
    var remainingAttemptsPublisher: Published<Int>.Publisher {
        get
    }
    
    // MARK: Account functions
    
    /// Update logged account info
    func update()
    func update(_ completion: ((AccountServiceResult) -> Void)?)
    
    /// Login into Adamant using passphrase.
    func loginWith(passphrase: String) async throws -> AccountServiceResult
    
    /// Login into Adamant using previously logged account
    func loginWithStoredAccount() async throws -> AccountServiceResult
    
    /// Logout
    func logout()
    
    /// Reload current wallets state
    func reloadWallets()
    
    // MARK: Stay in functions
    
    /// There is a stored account information in secured store
    var hasStayInAccount: Bool { get }
    
    /// Use TouchID or FaceID to log in
    var useBiometry: Bool { get }
    
    /// Save account data and use pincode to login
    ///
    /// - Parameters:
    ///   - pin: pincode to login
    ///   - completion: completion handler
    func setStayLoggedIn(pin: String, completion: @escaping (AccountServiceResult) -> Void)
    
    /// Remove stored data
    func dropSavedAccount()
    
    /// If we have stored data with pin, validate it. If no data saved, always returns false.
    func validatePin(_ pin: String, isInitialLoginAttempt: Bool) -> Bool
    
    /// Update use TouchID or FaceID to log in
    func updateUseBiometry(_ newValue: Bool)
}
