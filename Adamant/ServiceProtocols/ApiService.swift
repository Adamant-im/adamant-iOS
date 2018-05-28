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
			return NSLocalizedString("ApiService.Error.UserNotLogged", comment: "ApiService: User not logged error")
			
		case .accountNotFound:
			return NSLocalizedString("ApiService.Error.AccountNotFoundFormat", comment: "ApiService: Account not found error. Using %@ for address.")
			
		case .serverError(error: let error):
			return String.localizedStringWithFormat(NSLocalizedString("ApiService.Error.RemoteServerErrorFormat", comment: "ApiService: Remote server returned an error. Using %@ for error description"), error)
			
		case .internalError(let msg, let error):
			let message: String
			if let apiError = error as? ApiServiceError {
				message = apiError.localized
			} else if let error = error {
				message = String(describing: error)
			} else {
				message = msg
			}
			
			return String.localizedStringWithFormat(NSLocalizedString("ApiService.Error.InternalErrorFormat", comment: "ApiService: Bad internal application error, report a bug. Using %@ for error description"), message)
			
		case .networkError(error: _):
			return NSLocalizedString("ApiService.Error.NoConnection", comment: "ApiService: No connection message. Generally bad network.")
		}
	}
}

protocol ApiService: class {
	
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
	
	func getTransaction(id: UInt64, completion: @escaping (ApiServiceResult<Transaction>) -> Void)
	func getTransactions(forAccount: String, type: TransactionType, fromHeight: Int64?, offset: Int?, limit: Int?, completion: @escaping (ApiServiceResult<[Transaction]>) -> Void)
	
	
	// MARK: - Funds
	
	func transferFunds(sender: String, recipient: String, amount: Decimal, keypair: Keypair, completion: @escaping (ApiServiceResult<Bool>) -> Void)
	
	
	// MARK: - States
	
	/// - Returns: Transaction ID
	func store(key: String, value: String, type: StateType, sender: String, keypair: Keypair, completion: @escaping (ApiServiceResult<UInt64>) -> Void)
	
	
	// MARK: - Chats
	
	/// Get chat transactions (type 8)
	///
	/// - Parameters:
	///   - address: Transactions for specified account
	///   - height: From this height. Minimal value is 1.
	func getMessageTransactions(address: String, height: Int64?, offset: Int?, completion: @escaping (ApiServiceResult<[Transaction]>) -> Void)
	
	/// Send text message
	///   - completion: Contains processed transactionId, if success, or AdamantError, if fails.
	func sendMessage(senderId: String, recipientId: String, keypair: Keypair, message: String, nonce: String, completion: @escaping (ApiServiceResult<UInt64>) -> Void)
}
