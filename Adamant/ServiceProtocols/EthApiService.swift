//
//  EthApiService.swift
//  Adamant
//
//  Created by Anton Boyarkin on 16/06/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import web3swift

// MARK: - Notifications
extension Notification.Name {
	struct EthApiService {
		/// Raised when user has logged out.
		static let userLoggedOut = Notification.Name("adamant.ethApiService.userHasLoggedOut")
		
		/// Raised when user has successfully logged in.
		static let userLoggedIn = Notification.Name("adamant.ethApiService.userHasLoggedIn")
		
		private init() {}
	}
}

protocol EthApiService: class {
    var account: EthAccount? { get }
    
    // MARK: - Accounts
    func newAccount(byPassphrase passphrase: String, completion: @escaping (ApiServiceResult<EthAccount>) -> Void)
    
    // MARK: - Transactions
    func createTransaction(toAddress address: String, amount: Double, completion: @escaping (ApiServiceResult<TransactionIntermediate>) -> Void)
    func sendTransaction(transaction: TransactionIntermediate, completion: @escaping (ApiServiceResult<String>) -> Void)
    
    func sendFunds(toAddress address: String, amount: Double, completion: @escaping (ApiServiceResult<String>) -> Void)
    
    func getTransactions(_ completion: @escaping (ApiServiceResult<[EthTransaction]>) -> Void)
    func getTransaction(byHash hash: String, completion: @escaping (ApiServiceResult<Web3EthTransaction>) -> Void)
    
    // MARK: - Tools
    func getBalance(_ completion: @escaping (ApiServiceResult<String>) -> Void)
    func getBalance(byAddress address: String, completion: @escaping (ApiServiceResult<String>) -> Void)
    func getEthAddress(byAdamandAddress address: String, completion: @escaping (ApiServiceResult<String?>) -> Void)
}
