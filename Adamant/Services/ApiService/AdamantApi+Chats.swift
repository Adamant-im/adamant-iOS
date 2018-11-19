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
	func getMessageTransactions(address: String, height: Int64?, offset: Int?, completion: @escaping (ApiServiceResult<[Transaction]>) -> Void) {
		// MARK: 1. Prepare params
		var queryItems: [URLQueryItem] = [URLQueryItem(name: "isIn", value: address),
										  URLQueryItem(name: "orderBy", value: "timestamp:desc")]
		if let height = height, height > 0 { queryItems.append(URLQueryItem(name: "fromHeight", value: String(height))) }
		if let offset = offset { queryItems.append(URLQueryItem(name: "offset", value: String(offset))) }
		
		// MARK: 2. Build endpoint
		let endpoint: URL
		do {
			endpoint = try buildUrl(path: ApiCommands.Chats.get, queryItems: queryItems)
		} catch {
			let err = InternalError.endpointBuildFailed.apiServiceErrorWith(error: error)
			completion(.failure(err))
			return
		}
		
		// MARK: 3. Send
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
    
	func sendMessage(senderId: String, recipientId: String, keypair: Keypair, message: String, type: ChatType, nonce: String, completion: @escaping (ApiServiceResult<UInt64>) -> Void) {
        // MARK: 1. Prepare params
        let params: [String : Any] = [
            "type": TransactionType.chatMessage.rawValue,
            "senderId": senderId,
            "recipientId": recipientId,
            "publicKey": keypair.publicKey,
            "message": message,
            "own_message": nonce,
            "message_type": type.rawValue
        ]
        
        let headers = [
            "Content-Type": "application/json"
        ]
        
        // MARK: 2. Build Endpoints
        let normalizeEndpoint: URL
        let processEndpoin: URL
        
        do {
            normalizeEndpoint = try buildUrl(path: ApiCommands.Chats.normalizeTransaction)
            processEndpoin = try buildUrl(path: ApiCommands.Chats.processTransaction)
        } catch {
            let err = InternalError.endpointBuildFailed.apiServiceErrorWith(error: error)
            completion(.failure(err))
            return
        }
        
        // MARK: 3. Normalize transaction
        sendRequest(url: normalizeEndpoint, method: .post, parameters: params, encoding: .json, headers: headers) { (serverResponse: ApiServiceResult<ServerModelResponse<NormalizedTransaction>>) in
            switch serverResponse {
            case .success(let response):
                // MARK: 4.1. Check server errors.
                guard let normalizedTransaction = response.model else {
                    let error = AdamantApiService.translateServerError(response.error)
                    completion(.failure(error))
                    return
                }
                
                // MARK: 4.2. Sign normalized transaction
                guard let signature = self.adamantCore.sign(transaction: normalizedTransaction, senderId: senderId, keypair: keypair) else {
                    completion(.failure(InternalError.signTransactionFailed.apiServiceErrorWith(error: nil)))
                    return
                }
                
                // MARK: 4.3. Create transaction
                let transaction: [String: Any] = [
                    "type": normalizedTransaction.type.rawValue,
                    "amount": normalizedTransaction.amount,
                    "senderPublicKey": normalizedTransaction.senderPublicKey,
                    "requesterPublicKey": normalizedTransaction.requesterPublicKey ?? NSNull(),
                    "timestamp": normalizedTransaction.timestamp,
                    "recipientId": normalizedTransaction.recipientId ?? NSNull(),
                    "senderId": senderId,
                    "signature": signature,
                    "asset": [
                        "chat": [
                            "message": message,
                            "own_message": nonce,
                            "type": type.rawValue
                        ]
                    ]
                ]
                
                let params: [String: Any] = [
                    "transaction": transaction
                ]
                
                // MARK: 5. Send
                self.sendRequest(url: processEndpoin, method: .post, parameters: params, encoding: .json, headers: headers) { (serverResponse: ApiServiceResult<TransactionIdResponse>) in
                    switch serverResponse {
                    case .success(let response):
                        if let id = response.transactionId {
                            completion(.success(id))
                        } else {
                            let error = AdamantApiService.translateServerError(response.error)
                            completion(.failure(error))
                        }
                        
                    case .failure(let error):
                        completion(.failure(.networkError(error: error)))
                    }
                }
                
                
            case .failure(let error):
                completion(.failure(.networkError(error: error)))
            }
        }
    }
}
