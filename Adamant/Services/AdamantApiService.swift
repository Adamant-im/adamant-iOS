//
//  AdamantApiService.swift
//  Adamant-ios
//
//  Created by Anokhov Pavel on 06.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import Alamofire


private struct ApiCommands {
	static let Accounts = (
		root: "/api/accounts",
		getPublicKey: "/api/accounts/getPublicKey",
		newAccount: "/api/accounts/new"
	)
	
	static let Transactions = (
		root: "/api/transactions",
		getTransaction: "/api/transactions/get",
		normalizeTransaction: "/api/transactions/normalize",
		processTransaction: "/api/transactions/process"
	)
	
	static let Chats = (
		root: "/api/chats",
		get: "/api/chats/get",
		normalizeTransaction: "/api/chats/normalize",
		processTransaction: "/api/chats/process"
	)
	
	private init() {}
}


class AdamantApiService: ApiService {
	
	// MARK: - Dependencies
	let adamantCore: AdamantCore
	
	// MARK: - Properties
	let apiUrl: URL
	
	// MARK: - Initialization
	init(apiUrl: URL, adamantCore: AdamantCore) {
		self.apiUrl = apiUrl
		self.adamantCore = adamantCore
	}
	
	private func buildUrl(path: String, queryItems: [URLQueryItem]? = nil) throws -> URL {
		guard var components = URLComponents(url: apiUrl, resolvingAgainstBaseURL: false) else {
			throw AdamantError(message: "Internal API error: Can't parse API URL: \(apiUrl)")
		}
		
		components.path = path
		components.queryItems = queryItems
		
		return try components.asURL()
	}
}


// MARK: - Accounts
extension AdamantApiService {
	func newAccount(byPublicKey publicKey: String, completionHandler: @escaping (Account?, AdamantError?) -> Void) {
		let endpoint: URL
		do {
			endpoint = try buildUrl(path: ApiCommands.Accounts.newAccount)
		} catch {
			completionHandler(nil, AdamantError(message: "Failed to build endpoint url", error: error))
			return
		}
		
		let params = [
			"publicKey": publicKey
		]
		let headers: HTTPHeaders = [
			"Content-Type": "application/json"
		]
		
		sendRequest(url: endpoint, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers, completionHandler: { (response: ServerModelResponse<Account>?, error) in
			guard let r = response, r.success, let account = r.model else {
				completionHandler(nil, AdamantError(message: response?.error ?? "Failed to create account", error: error))
				return
			}
			
			completionHandler(account, nil)
		})
	}
	
	func getAccount(byPassphrase passphrase: String, completionHandler: @escaping (Account?, AdamantError?) -> Void) {
		getPublicKey(byPassphrase: passphrase) { (key, error) in
			guard let key = key else {
				completionHandler(nil, AdamantError(message: "Can't get account by passphrase: \(passphrase)", error: error))
				return
			}
			
			self.getAccount(byPublicKey: key, completionHandler: completionHandler)
		}
	}
	
	func getAccount(byPublicKey publicKey: String, completionHandler: @escaping (Account?, AdamantError?) -> Void) {
		let endpoint: URL
		do {
			endpoint = try buildUrl(path: ApiCommands.Accounts.root, queryItems: [URLQueryItem(name: "publicKey", value: publicKey)])
		} catch {
			completionHandler(nil, AdamantError(message: "Failed to build endpoint url", error: error))
			return
		}
		
		sendRequest(url: endpoint) { (response: ServerModelResponse<Account>?, error) in
			guard let r = response, r.success, let account = r.model else {
				completionHandler(nil, AdamantError(message: response?.error ?? "Failed to get account", error: error))
				return
			}
			
			completionHandler(account, nil)
		}
	}
}


// MARK: - Keys
extension AdamantApiService {
	func getPublicKey(byPassphrase passphrase: String, completionHandler: @escaping (String?, AdamantError?) -> Void) {
		guard let keypair = adamantCore.createKeypairFor(passphrase: passphrase) else {
			completionHandler(nil, AdamantError(message: "Can't create keypair for passphrase: \(passphrase)"))
			return
		}
		
		completionHandler(keypair.publicKey, nil)
	}
	
	func getPublicKey(byAddress address: String, completionHandler: @escaping (String?, AdamantError?) -> Void) {
		let endpoint: URL
		do {
			endpoint = try buildUrl(path: ApiCommands.Accounts.getPublicKey, queryItems: [URLQueryItem(name: "address", value: address)])
		} catch {
			completionHandler(nil, AdamantError(message: "Failed to build endpoint url", error: error))
			return
		}
		
		sendRequest(url: endpoint) { (response: GetPublicKeyResponse?, error) in
			guard let r = response, r.success, let key = r.publicKey else {
				completionHandler(nil, AdamantError(message: response?.error ?? "Can't get publickey", error: error))
				return
			}
			
			completionHandler(key, nil)
		}
	}
}


// MARK: - Transactions
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


// MAKR: - Transfers
extension AdamantApiService {
	func transferFunds(sender: String, recipient: String, amount: UInt, keypair: Keypair, completionHandler: @escaping (Bool, AdamantError?) -> Void) {
		let params: [String : Any] = [
			"type": TransactionType.send.rawValue,
			"amount": amount,
			"recipientId": recipient,
			"senderId": sender,
			"publicKey": keypair.publicKey
		]
		let headers: HTTPHeaders = [
			"Content-Type": "application/json"
		]
		
		do {
			let normalizeEndpoint = try buildUrl(path: ApiCommands.Transactions.normalizeTransaction)
			let processEndpoin = try buildUrl(path: ApiCommands.Transactions.processTransaction)
			
			sendRequest(url: normalizeEndpoint, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers, completionHandler: { (response: ServerModelResponse<NormalizedTransaction>?, error) in
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
				
				self.sendRequest(url: processEndpoin, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers, completionHandler: { (response: ServerResponse?, error) in
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


// MARK: - Chats
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
		
		let headers: HTTPHeaders = [
			"Content-Type": "application/json"
		]
		
		do {
			let normalizeEndpoint = try buildUrl(path: ApiCommands.Chats.normalizeTransaction)
			let processEndpoin = try buildUrl(path: ApiCommands.Chats.processTransaction)
			
			sendRequest(url: normalizeEndpoint, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers) { (response: ServerModelResponse<NormalizedTransaction>?, error) in
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
				
				self.sendRequest(url: processEndpoin, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers) { (r: ProcessTransactionResponse?, error) in
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


// MARK: - Tools
extension AdamantApiService {
	private func sendRequest<T: Decodable>(url: URLConvertible,
										   method: HTTPMethod = .get,
										   parameters: Parameters? = nil,
										   encoding: ParameterEncoding = URLEncoding.default,
										   headers: HTTPHeaders? = nil,
										   completionHandler: @escaping (T?, Error?) -> Void) {
		Alamofire.request(url, method: method, parameters: parameters, encoding: encoding, headers: headers).response { response in
			guard let data = response.data else {
				completionHandler(nil, response.error)
				return
			}
			
			do {
				let response: T = try JSONDecoder().decode(T.self, from: data)
				completionHandler(response, nil)
			} catch {
				completionHandler(nil, AdamantError(message: "Error parsing server response", error: error))
			}
		}
	}
}
