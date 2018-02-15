//
//  ApiService.swift
//  Adamant
//
//  Created by Anokhov Pavel on 05.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

enum ApiServiceResult<T> {
	case success(T)
	case failure(ApiServiceError)
}

enum ApiServiceError: Error {
	case notLogged
	case accountNotFound
	case serverError(error: String)
	case internalError(message: String, error: Error?)
	case networkError(error: Error)
	
	var localized: String {
		switch self {
		case .notLogged:
			return NSLocalizedString("apiService.errors.user-not-logged", comment: "User not logged")
			
		case .accountNotFound:
			return NSLocalizedString("apiService.errors.account-not-found-format", comment: "Account not found: %@")
			
		case .serverError(error: let error):
			return String.localizedStringWithFormat(NSLocalizedString("apiService.errors.remote-server-error-format", comment: "Remote server error: %@"), error)
			
		case .internalError(_, let error as ApiServiceError):
			return String.localizedStringWithFormat(NSLocalizedString("apiService.errors.internal-error-format", comment: "Internal error: %@"), error.localized)
			
		case .internalError(_, let error):
			return String.localizedStringWithFormat(NSLocalizedString("apiService.errors.internal-error-format", comment: "Internal error: %@"), String(describing: error))
			
		case .networkError(error: _):
			return NSLocalizedString("apiService.errors.connection-failed", comment: "No connection message")
		}
	}
}

protocol ApiService {
	
	/// Default is async queue with .utilities priority.
	var defaultResponseDispatchQueue: DispatchQueue { get set }
	
	// MARK: - Accounts
	
	func newAccount(byPublicKey publicKey: String, completion: @escaping (ApiServiceResult<Account>) -> Void)
	func getAccount(byPassphrase passphrase: String, completion: @escaping (ApiServiceResult<Account>) -> Void)
	func getAccount(byPublicKey publicKey: String, completion: @escaping (ApiServiceResult<Account>) -> Void)
	func getAccount(byAddress address: String, completion: @escaping (ApiServiceResult<Account>) -> Void)
	
	
	// MARK: - Keys
	
	func getPublicKey(byAddress address: String, completion: @escaping (ApiServiceResult<String>) -> Void)
	
	
	// MARK: - Transactions
	
	func getTransaction(id: UInt, completion: @escaping (ApiServiceResult<Transaction>) -> Void)
	func getTransactions(forAccount: String, type: TransactionType, fromHeight: UInt?, completion: @escaping (ApiServiceResult<[Transaction]>) -> Void)
	
	
	// MARK: - Funds
	
	func transferFunds(sender: String, recipient: String, amount: UInt, keypair: Keypair, completion: @escaping (ApiServiceResult<Bool>) -> Void)
	
	
	// MARK: - Chats
	
	/// Get chat transactions (type 8)
	///
	/// - Parameters:
	///   - account: Transactions for specified account
	///   - height: From this height. Minimal value is 1.
	func getChatTransactions(account: String, height: Int?, offset: Int?, completion: @escaping (ApiServiceResult<[Transaction]>) -> Void)
	
	/// Send text message
	///   - completion: Contains processed transactionId, if success, or AdamantError, if fails.
	func sendMessage(senderId: String, recipientId: String, keypair: Keypair, message: String, nonce: String, completion: @escaping (ApiServiceResult<UInt>) -> Void)
}
