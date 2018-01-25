//
//  AdamantApi+Transfers.swift
//  Adamant
//
//  Created by Anokhov Pavel on 24.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

extension AdamantApiService {
	func transferFunds(sender: String, recipient: String, amount: UInt, keypair: Keypair, completionHandler: @escaping (Bool, AdamantError?) -> Void) {
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
		
		do {
			let normalizeEndpoint = try buildUrl(path: ApiCommands.Transactions.normalizeTransaction)
			let processEndpoin = try buildUrl(path: ApiCommands.Transactions.processTransaction)
			
			sendRequest(url: normalizeEndpoint, method: .post, parameters: params, encoding: .json, headers: headers, completionHandler: { (response: ServerModelResponse<NormalizedTransaction>?, error) in
				guard let r = response, r.success, let nt = r.model else {
					completionHandler(false, AdamantError(message: response?.error ?? "Failed to get transactions", error: error))
					return
				}
				
				guard let signature = self.adamantCore.sign(transaction: nt, senderId: sender, keypair: keypair) else {
					completionHandler(false, AdamantError(message: "Failed to sign transaction"))
					return
				}
				
				let transaction: [String: Any] = [
					"type": TransactionType.send.rawValue,
					"amount": amount,
					"senderPublicKey": keypair.publicKey,
					"requesterPublicKey": nt.requesterPublicKey ?? NSNull(),
					"timestamp": nt.timestamp,
					"recipientId": recipient,
					"senderId": sender,
					"signature": signature
				]
				
				let params: [String: Any] = [
					"transaction": transaction
				]
				
				self.sendRequest(url: processEndpoin, method: .post, parameters: params, encoding: .json, headers: headers, completionHandler: { (response: ServerResponse?, error) in
					guard let r = response, r.success else {
						completionHandler(false, AdamantError(message: response?.error ?? "Failed to process transaction", error: error))
						return
					}
					
					completionHandler(true, nil)
				})
			})
		} catch {
			completionHandler(false, AdamantError(message: "Failed to send request", error: error))
		}
	}
}
