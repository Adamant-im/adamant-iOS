//
//  AdamantApiService.swift
//  Adamant-ios
//
//  Created by Anokhov Pavel on 06.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import Alamofire

private struct ApiCommand {
	static let Accounts = ApiCommand("/api/accounts")
	static let GetPublicKey = ApiCommand("/api/accounts/getPublicKey")
	static let Transactions = ApiCommand("/api/transactions")
	static let NormalizeTransaction = ApiCommand("/api/transactions/normalize")
	static let ProcessTransaction = ApiCommand("/api/transactions/process")
	
	let path: String
	private init(_ path: String) {
		self.path = path
	}
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
	
	private func buildUrl(command: ApiCommand, queryItems: [URLQueryItem]?) throws -> URL {
		guard var components = URLComponents(url: apiUrl, resolvingAgainstBaseURL: false) else {
			throw AdamantError(message: "Internal API error: Can't parse API URL: \(apiUrl)")
		}
		
		components.path = command.path
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
			endpoint = try buildUrl(command: ApiCommand.Accounts, queryItems: [URLQueryItem(name: "publicKey", value: publicKey)])
		} catch {
			completionHandler(nil, AdamantError(message: "Failed to build endpoint url", error: error))
			return
		}
		
		sendRequest(url: endpoint) { (response: AccountsResponse?, error) in
			guard let r = response, r.success, let account = r.account else {
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
			endpoint = try buildUrl(command: ApiCommand.GetPublicKey, queryItems: [URLQueryItem(name: "account", value: address)])
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
			endpoint = try buildUrl(command: ApiCommand.Transactions, queryItems: [URLQueryItem(name: "inId", value: account),
																				   URLQueryItem(name: "and:type", value: String(type.rawValue))])
		} catch {
			completionHandler(nil, AdamantError(message: "Failed to build endpoint url", error: error))
			return
		}
		
		sendRequest(url: endpoint) { (response: TransactionsResponse?, error) in
			guard let r = response, r.success, let transactions = r.transactions else {
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
			let normalizeEndpoint = try buildUrl(command: ApiCommand.NormalizeTransaction, queryItems: nil)
			let processEndpoin = try buildUrl(command: ApiCommand.ProcessTransaction, queryItems: nil)
			
			sendRequest(url: normalizeEndpoint, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headersContentTypeJson, completionHandler: { (response: NormalizeTransactionResponse?, error) in
				guard let r = response, r.success, let nt = r.normalizedTransaction else {
					completionHandler(false, AdamantError(message: response?.error ?? "Failed to send transactions", error: error))
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
				
				self.sendRequest(url: processEndpoin, method: .post, parameters: request, encoding: JSONEncoding.default, headers: headersContentTypeJson, completionHandler: { (response: ProcessTransactionResponse?, error) in
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
