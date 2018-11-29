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

// MARK: - Error
enum ApiServiceError: Error {
	case notLogged
	case accountNotFound
	case serverError(error: String)
	case internalError(message: String, error: Error?)
	case networkError(error: Error)
	
	var localized: String {
		switch self {
		case .notLogged:
			return String.adamantLocalized.sharedErrors.userNotLogged
			
		case .accountNotFound:
			return String.adamantLocalized.sharedErrors.accountNotFound
			
		case .serverError(let error):
			return String.adamantLocalized.sharedErrors.remoteServerError(message: error)
			
		case .internalError(let msg, let error):
			let message: String
			if let apiError = error as? ApiServiceError {
				message = apiError.localized
			} else if let error = error {
				message = error.localizedDescription
			} else {
				message = msg
			}
			
			return
				String.adamantLocalized.sharedErrors.internalError(message: message)
			
		case .networkError(error: _):
			return String.adamantLocalized.sharedErrors.networkError
		}
	}
}

extension ApiServiceError: RichError {
	var message: String {
		return localized
	}
	
	var level: ErrorLevel {
		switch self {
		case .accountNotFound, .notLogged, .networkError:
			return .warning
			
		case .internalError, .serverError:
			return .error
		}
	}
	
	var internalError: Error? {
		switch self {
		case .accountNotFound, .notLogged, .serverError:
			return nil
			
		case .internalError(_, let error):
			return error
			
		case .networkError(let error):
			return error
		}
	}
}

extension ApiServiceError: Equatable {
	static func == (lhs: ApiServiceError, rhs: ApiServiceError) -> Bool {
		switch (lhs, rhs) {
		case (.notLogged, .notLogged):
			return true
			
		case (.accountNotFound, .accountNotFound):
			return true
			
		case (.serverError(let le), .serverError(let re)):
			return le == re
			
		case (.internalError(let lm, _), .internalError(let rm, _)):
			return lm == rm
			
		case (.networkError, .networkError):
			return true
			
		default:
			return false
		}
	}
}


// - MARK: ApiService
protocol ApiService: class {
	
	/// Default is async queue with .utilities priority.
	var defaultResponseDispatchQueue: DispatchQueue { get }
    
    // MARK: - Servers list
	
	/// Current node
	var node: Node? { get }
	
	/// Request new node from source
	func refreshNode()
	
	// MARK: - Peers
	
	func getNodeVersion(url: URL, completion: @escaping (ApiServiceResult<NodeVersion>) -> Void)
	
	
	// MARK: - Accounts
	
	func newAccount(byPublicKey publicKey: String, completion: @escaping (ApiServiceResult<AdamantAccount>) -> Void)
	func getAccount(byPassphrase passphrase: String, completion: @escaping (ApiServiceResult<AdamantAccount>) -> Void)
	func getAccount(byPublicKey publicKey: String, completion: @escaping (ApiServiceResult<AdamantAccount>) -> Void)
	func getAccount(byAddress address: String, completion: @escaping (ApiServiceResult<AdamantAccount>) -> Void)
	
	
	// MARK: - Keys
	
	func getPublicKey(byAddress address: String, completion: @escaping (ApiServiceResult<String>) -> Void)
	
	
	// MARK: - Transactions
	
	func getTransaction(id: UInt64, completion: @escaping (ApiServiceResult<Transaction>) -> Void)
	func getTransactions(forAccount: String, type: TransactionType, fromHeight: Int64?, offset: Int?, limit: Int?, completion: @escaping (ApiServiceResult<[Transaction]>) -> Void)
	
	
	// MARK: - Funds
	
	func transferFunds(sender: String, recipient: String, amount: Decimal, keypair: Keypair, completion: @escaping (ApiServiceResult<UInt64>) -> Void)
	
	
	// MARK: - States
	
	/// - Returns: Transaction ID
	func store(key: String, value: String, type: StateType, sender: String, keypair: Keypair, completion: @escaping (ApiServiceResult<UInt64>) -> Void)
	func get(key: String, sender: String, completion: @escaping (ApiServiceResult<String?>) -> Void)
	
	// MARK: - Chats
	
	/// Get chat transactions (type 8)
	///
	/// - Parameters:
	///   - address: Transactions for specified account
	///   - height: From this height. Minimal value is 1.
	func getMessageTransactions(address: String, height: Int64?, offset: Int?, completion: @escaping (ApiServiceResult<[Transaction]>) -> Void)
	
	/// Send text message
	///   - completion: Contains processed transactionId, if success, or AdamantError, if fails.
    func sendMessage(senderId: String, recipientId: String, keypair: Keypair, message: String, type: ChatType, amount: Decimal?, nonce: String, completion: @escaping (ApiServiceResult<UInt64>) -> Void)

    // MARK: - Delegates
    
    /// Get delegates
    func getDelegates(limit: Int, completion: @escaping (ApiServiceResult<[Delegate]>) -> Void)
    func getDelegatesWithVotes(for address: String, limit: Int, completion: @escaping (ApiServiceResult<[Delegate]>) -> Void)
    
    /// Get delegate forge details
    func getForgedByAccount(publicKey: String, completion: @escaping (ApiServiceResult<DelegateForgeDetails>) -> Void)
    /// Get delegate forgeing time
    func getForgingTime(for delegate: Delegate, completion: @escaping (ApiServiceResult<Int>) -> Void)
    
    /// Send vote transaction for delegates
    func voteForDelegates(from address: String, keypair: Keypair, votes: [DelegateVote], completion: @escaping (ApiServiceResult<UInt64>) -> Void)
}
