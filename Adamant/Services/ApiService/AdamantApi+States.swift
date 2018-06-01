//
//  AdamantApi+States.swift
//  Adamant
//
//  Created by Anokhov Pavel on 23.05.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

extension AdamantApiService.ApiCommands {
	static let States = (
		root: "/api/states",
		getTransactions: "/api/states/get",
		store: "/api/states/store"
	)
}

extension AdamantApiService {
	func store(key: String, value: String, type: StateType, sender: String, keypair: Keypair, completion: @escaping (ApiServiceResult<UInt64>) -> Void) {
		
		// MARK: 1. Create and sign transaction
		let asset = TransactionAsset(chat: nil, state: StateAsset(key: key, value: value, type: .keyValue))
		let transaction = NormalizedTransaction(type: .state,
												amount: 0,
												senderPublicKey: keypair.publicKey,
												requesterPublicKey: nil,
												date: Date(),
												recipientId: nil,
												asset: asset)
		guard let signature = adamantCore.sign(transaction: transaction, senderId: sender, keypair: keypair) else {
			completion(.failure(.internalError(message: "Failed to sign transaction", error: nil)))
			return
		}
		
		let params: [String: Any] = [
			"transaction": [
				"type": transaction.type.rawValue,
				"amount": transaction.amount,
				"senderPublicKey": transaction.senderPublicKey,
				"senderId": sender,
				"timestamp": transaction.timestamp,
				"signature": signature,
				"recipientId": NSNull(),
				"asset": [
					"state": [
						"key": key,
						"value": value,
						"type": type.rawValue
					]
				]
			]
		]
		
		let headers = [
			"Content-Type": "application/json"
		]
		
		// MARK: 2. Build endpoints
		let endpoint: URL
		
		do {
			endpoint = try buildUrl(path: ApiCommands.States.store)
		} catch {
			let err = InternalError.endpointBuildFailed.apiServiceErrorWith(error: error)
			completion(.failure(err))
			return
		}
		
		// MARK: 3. Send
		sendRequest(url: endpoint, method: .post, parameters: params, encoding: .json, headers: headers) { (serverResponse: ApiServiceResult<TransactionIdResponse>) in
			switch serverResponse {
			case .success(let response):
				if let id = response.transactionId {
					completion(.success(id))
				} else {
					completion(ApiServiceResult.success(0))
				}
				
			case .failure(let error):
				completion(.failure(.networkError(error: error)))
			}
		}
	}
}
