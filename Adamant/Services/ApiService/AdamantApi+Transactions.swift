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
	func getTransaction(id: UInt, completion: @escaping (ApiServiceResult<Transaction>) -> Void) {
		let endpoint: URL
		do {
			endpoint = try buildUrl(path: ApiCommands.Transactions.getTransaction, queryItems: [URLQueryItem(name: "id", value: String(id))])
		} catch {
			let err = InternalError.endpointBuildFailed.apiServiceErrorWith(error: error)
			completion(.failure(err))
			return
		}
		
		sendRequest(url: endpoint) { (serverResponse: ApiServiceResult<ServerModelResponse<Transaction>>) in
			switch serverResponse {
			case .success(let response):
				if let model = response.model {
					completion(.success(model))
				} else {
					let error = AdamantApiService.translateServerError(response.error)
					completion(.failure(error))
				}
				
			case .failure(let error):
				completion(.failure(.networkError(error: error)))
			}
		}
	}
	
	func getTransactions(forAccount account: String, type: TransactionType, fromHeight: UInt?, completion: @escaping (ApiServiceResult<[Transaction]>) -> Void) {
		var queryItems = [URLQueryItem(name: "inId", value: account),
						  URLQueryItem(name: "and:type", value: String(type.rawValue))]
		
		if let fromHeight = fromHeight, fromHeight > 0 {
			queryItems.append(URLQueryItem(name: "and:fromHeight", value: String(fromHeight)))
		}
		
		let endpoint: URL
		do {
			endpoint = try buildUrl(path: ApiCommands.Transactions.root, queryItems: queryItems)
		} catch {
			let err = InternalError.endpointBuildFailed.apiServiceErrorWith(error: error)
			completion(.failure(err))
			return
		}
		
		sendRequest(url: endpoint) { (serverResponse: ApiServiceResult<ServerCollectionResponse<Transaction>>) in
			switch serverResponse {
			case .success(let response):
				if let collection = response.collection {
					completion(.success(collection))
				} else {
					let error = AdamantApiService.translateServerError(response.error)
					completion(.failure(error))
				}
				
			case .failure(let error):
				completion(.failure(.networkError(error: error)))
			}
		}
	}
}
