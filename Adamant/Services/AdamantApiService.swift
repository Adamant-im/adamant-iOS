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
		getPublicKey: "/api/accounts/getPublicKey"
	)
	
	static let Transactions = (
		root: "/api/transactions",
		normalizeTransaction: "/api/transactions/normalize",
		processTransaction: "/api/transactions/process"
	)
	
	static let Chats = (
		root: "/api/chats",
		get: "/api/chats/get"
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
	
	private func buildUrl(path: String, queryItems: [URLQueryItem]?) throws -> URL {
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
		let parameters: [String : Any] = [
			"type": TransactionType.send.rawValue,
			"amount": amount,
			"recipientId": recipient,
			"senderId": sender,
			"publicKey": keypair.publicKey
		]
		let headersContentTypeJson: HTTPHeaders = [
			"Content-Type": "application/json"
		]
		
		do {
			let normalizeEndpoint = try buildUrl(path: ApiCommands.Transactions.normalizeTransaction, queryItems: nil)
			let processEndpoin = try buildUrl(path: ApiCommands.Transactions.processTransaction, queryItems: nil)
			
			sendRequest(url: normalizeEndpoint, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headersContentTypeJson, completionHandler: { (response: ServerModelResponse<NormalizedTransaction>?, error) in
				guard let r = response, r.success, let nt = r.model else {
					completionHandler(false, AdamantError(message: response?.error ?? "Failed to get transactions", error: error))
					return
				}
				
				guard let signature = self.adamantCore.sign(transaction: nt, senderId: sender, keypair: keypair) else {
					completionHandler(false, AdamantError(message: "Failed to sign transaction"))
					return
				}
				
				let transaction: [String: Encodable] = [
					"type": TransactionType.send.rawValue,
					"amount": amount,
					"senderPublicKey": keypair.publicKey,
					"requesterPublicKey": nt.requesterPublicKey,
					"timestamp": nt.timestamp,
					"recipientId": recipient,
					"senderId": sender,
					"signature": signature
				]
				
				let request: [String: Encodable] = [
					"transaction": transaction
				]
				
				self.sendRequest(url: processEndpoin, method: .post, parameters: request, encoding: JSONEncoding.default, headers: headersContentTypeJson, completionHandler: { (response: ServerResponse?, error) in
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
