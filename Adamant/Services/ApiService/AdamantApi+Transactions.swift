//
//  AdamantApi+Transactions.swift
//  Adamant
//
//  Created by Anokhov Pavel on 24.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

extension AdamantApiService.ApiCommands {
	static let Transactions = (
		root: "/api/transactions",
		getTransaction: "/api/transactions/get",
		normalizeTransaction: "/api/transactions/normalize",
		processTransaction: "/api/transactions/process"
	)
}

extension AdamantApiService {
	func getTransaction(id: UInt, completionHandler: @escaping (Transaction?, AdamantError?) -> Void) {
		let endpoint: URL
		do {
			endpoint = try buildUrl(path: ApiCommands.Transactions.getTransaction, queryItems: [URLQueryItem(name: "id", value: String(id))])
		} catch {
			completionHandler(nil, AdamantError(message: "Failed to build endpoint url", error: error))
			return
		}
		
		sendRequest(url: endpoint) { (response: ServerModelResponse<Transaction>?, error) in
			guard let r = response, r.success, let transaction = r.model else {
				completionHandler(nil, AdamantError(message: response?.error ?? "Failed to get transaction", error: error))
				return
			}
			
			completionHandler(transaction, nil)
		}
	}
	
	func getTransactions(forAccount account: String, type: TransactionType, completionHandler: @escaping ([Transaction]?, AdamantError?) -> Void) {
		let endpoint: URL
		do {
			endpoint = try buildUrl(path: ApiCommands.Transactions.root, queryItems: [URLQueryItem(name: "inId", value: account),
																					  URLQueryItem(name: "and:type", value: String(type.rawValue))])
		} catch {
			completionHandler(nil, AdamantError(message: "Failed to build endpoint url", error: error))
			return
		}
		
		sendRequest(url: endpoint) { (response: ServerCollectionResponse<Transaction>?, error) in
			guard let r = response, r.success, let transactions = r.collection else {
				completionHandler(nil, AdamantError(message: response?.error ?? "Failed to get transactions", error: error))
				return
			}
			
			completionHandler(transactions, nil)
		}
	}
}
