//
//  LskApiServerProtocol.swift
//  Adamant
//
//  Created by Anton Boyarkin on 12/07/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import Lisk

protocol LskApiServiceProtocol: class {
    
    var account: LskAccount? { get }
    
    // MARK: - Accounts
    func newAccount(byPassphrase passphrase: String, completion: @escaping (ApiServiceResult<LskAccount>) -> Void)
    
    // MARK: - Transactions
    func sendFunds(toAddress address: String, amount: Double, completion: @escaping (ApiServiceResult<String>) -> Void)
    func getTransactions(_ completion: @escaping (ApiServiceResult<[Transactions.TransactionModel]>) -> Void)
    func getTransaction(byHash hash: String, completion: @escaping (ApiServiceResult<Transactions.TransactionModel>) -> Void)
    
    // MARK: - Tools
    func getBalance(_ completion: @escaping (ApiServiceResult<String>) -> Void)
    func getLskAddress(byAdamandAddress address: String, completion: @escaping (ApiServiceResult<String?>) -> Void)
}
