//
//  AdamantApi+Transfers.swift
//  Adamant
//
//  Created by Anokhov Pavel on 24.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

extension AdamantApiService {
	func transferFunds(sender: String, recipient: String, amount: UInt, keypair: Keypair, completion: @escaping (ApiServiceResult<Bool>) -> Void) {
		let params: [String : Any] = [
			"type": TransactionType.send.rawValue,
			"amount": amount,
			"recipientId": recipient,
			"senderId": sender,
			"publicKey": keypair.publicKey
		]
		let headers = [
			"Content-Type": "application/json"
		]
		
		let normalizeEndpoint: URL
		let processEndpoin: URL
		
		do {
			normalizeEndpoint = try buildUrl(path: ApiCommands.Transactions.normalizeTransaction)
			processEndpoin = try buildUrl(path: ApiCommands.Transactions.processTransaction)
		} catch {
			let err = InternalErrors.endpointBuildFailed.apiServiceErrorWith(error: error)
			completion(.failure(err))
			return
		}
		
		sendRequest(url: normalizeEndpoint, method: .post, parameters: params, encoding: .json, headers: headers) { (serverResponse: ApiServiceResult<ServerModelResponse<NormalizedTransaction>>) in
			switch serverResponse {
			case .success(let response):
				guard let model = response.model else {
					let error = AdamantApiService.translateServerError(response.error)
					completion(.failure(error))
					return
				}
				
				guard let signature = self.adamantCore.sign(transaction: model, senderId: sender, keypair: keypair) else {
					completion(.failure(InternalErrors.signTransactionFailed.apiServiceErrorWith(error: nil)))
					return
				}
				
				let transaction: [String: Any] = [
					"type": TransactionType.send.rawValue,
					"amount": amount,
					"senderPublicKey": keypair.publicKey,
					"requesterPublicKey": model.requesterPublicKey ?? NSNull(),
					"timestamp": model.timestamp,
					"recipientId": recipient,
					"senderId": sender,
					"signature": signature
				]
				
				let params: [String: Any] = [
					"transaction": transaction
				]
				
				self.sendRequest(url: processEndpoin, method: .post, parameters: params, encoding: .json, headers: headers) { (response: ApiServiceResult<ServerResponse>) in
					switch response {
					case .success(_):
						completion(.success(true))
						
					case .failure(let error):
						completion(.failure(error))
					}
				}
				
			case .failure(let error):
				completion(.failure(.networkError(error: error)))
			}
		}
	}
}
