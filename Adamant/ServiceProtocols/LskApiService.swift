//
//  LskApiServerProtocol.swift
//  Adamant
//
//  Created by Anton Boyarkin on 12/07/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import Lisk

// MARK: - Notifications
extension Notification.Name {
	struct LskApiService {
		/// Raised when user has logged out.
		static let userLoggedOut = Notification.Name("adamant.lskApiService.userHasLoggedOut")
		
		/// Raised when user has successfully logged in.
		static let userLoggedIn = Notification.Name("adamant.lskApiService.userHasLoggedIn")
		
		private init() {}
	}
}

protocol LskApiService: class {
    
    var account: LskAccount? { get }
    
    // MARK: - Accounts
    func newAccount(byPassphrase passphrase: String, completion: @escaping (ApiServiceResult<LskAccount>) -> Void)
    
    // MARK: - Transactions
    func createTransaction(toAddress address: String, amount: Double, completion: @escaping (ApiServiceResult<LocalTransaction>) -> Void)
    func sendTransaction(transaction: LocalTransaction, completion: @escaping (ApiServiceResult<String>) -> Void)
    
    func sendFunds(toAddress address: String, amount: Double, completion: @escaping (ApiServiceResult<String>) -> Void)
    func getTransactions(_ completion: @escaping (ApiServiceResult<[Transactions.TransactionModel]>) -> Void)
    func getTransaction(byHash hash: String, completion: @escaping (ApiServiceResult<Transactions.TransactionModel>) -> Void)
    
    // MARK: - Tools
    func getBalance(_ completion: @escaping (ApiServiceResult<String>) -> Void)
    func getLskAddress(byAdamandAddress address: String, completion: @escaping (ApiServiceResult<String?>) -> Void)
}
