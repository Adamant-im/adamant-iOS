//
//  AdamantApi+Chats.swift
//  Adamant
//
//  Created by Anokhov Pavel on 24.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

extension AdamantApiService.ApiCommands {
	static let Chats = (
		root: "/api/chats",
		get: "/api/chats/get",
		normalizeTransaction: "/api/chats/normalize",
		processTransaction: "/api/chats/process"
	)
}

extension AdamantApiService {
	func getChatTransactions(account: String, height: Int?, offset: Int?, completionHandler: @escaping ([Transaction]?, AdamantError?) -> Void) {
		var queryItems: [URLQueryItem] = [URLQueryItem(name: "isIn", value: account)]
		if let height = height { queryItems.append(URLQueryItem(name: "fromHeight", value: String(height))) }
		if let offset = offset { queryItems.append(URLQueryItem(name: "offset", value: String(offset))) }
		
		let endpoint: URL
		do {
			endpoint = try buildUrl(path: ApiCommands.Chats.get, queryItems: queryItems)
		} catch {
			completionHandler(nil, AdamantError(message: "Failed to build endpoint url", error: error))
			return
		}
		
		sendRequest(url: endpoint) { (response: ServerCollectionResponse<Transaction>?, error) in
			guard let r = response, r.success, let collection = r.collection else {
				completionHandler(nil, AdamantError(message: response?.error ?? "Failed to get transactions", error: error))
				return
			}
			
			completionHandler(collection, nil)
		}
	}
	
	func sendMessage(senderId: String, recipientId: String, keypair: Keypair, message: String, nonce: String, completionHandler: @escaping (UInt?, AdamantError?) -> Void) {
		let params: [String : Any] = [
			"type": TransactionType.chatMessage.rawValue,
			"senderId": senderId,
			"recipientId": recipientId,
			"publicKey": keypair.publicKey,
			"message": message,
			"own_message": nonce
		]
		
		let headers = [
			"Content-Type": "application/json"
		]
		
		do {
			let normalizeEndpoint = try buildUrl(path: ApiCommands.Chats.normalizeTransaction)
			let processEndpoin = try buildUrl(path: ApiCommands.Chats.processTransaction)
			
			sendRequest(url: normalizeEndpoint, method: .post, parameters: params, encoding: .json, headers: headers) { (response: ServerModelResponse<NormalizedTransaction>?, error) in
				guard let r = response, r.success, let nt = r.model else {
					completionHandler(nil, AdamantError(message: response?.error ?? "Failed to get normalized transaction", error: error))
					return
				}
				
				guard let signature = self.adamantCore.sign(transaction: nt, senderId: senderId, keypair: keypair) else {
					completionHandler(nil, AdamantError(message: "Failed to sign transaction"))
					return
				}
				
				let transaction: [String: Any] = [
					"type": nt.type.rawValue,
					"amount": nt.amount,
					"senderPublicKey": nt.senderPublicKey,
					"requesterPublicKey": nt.requesterPublicKey ?? NSNull(),
					"timestamp": nt.timestamp,
					"recipientId": nt.recipientId,
					"senderId": senderId,
					"signature": signature,
					"asset": [
						"chat": [
							"message": message,
							"own_message": nonce,
							"type": 0
						]
					]
				]
				
				let params: [String: Any] = [
					"transaction": transaction
				]
				
				self.sendRequest(url: processEndpoin, method: .post, parameters: params, encoding: .json, headers: headers) { (r: ProcessTransactionResponse?, error) in
					guard let response = r, response.success, let transactionId = response.transactionId else {
						completionHandler(nil, AdamantError(message: r?.error ?? "Failed to process transaction", error: error))
						return
					}
					
					completionHandler(transactionId, nil)
				}
			}
		} catch {
			completionHandler(nil, AdamantError(message: "Failed to send request", error: error))
		}
	}
}
