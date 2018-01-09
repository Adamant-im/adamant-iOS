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
	static let Transactions = ApiCommand("/api/transactions")
	
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
	
	func getAccount(byPublicKey publicKey: AdamantHash, completionHandler: @escaping (Account?, AdamantError?) -> Void) {
		let endpoint: URL
		do {
			endpoint = try buildUrl(command: ApiCommand.Accounts, queryItems: [URLQueryItem(name: "publicKey", value: publicKey.hex)])
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
	
	func getPublicKey(byPassphrase passphrase: String, completionHandler: @escaping (AdamantHash?, AdamantError?) -> Void) {
		guard let keypair = adamantCore.createKeypairFor(passphrase: passphrase) else {
			completionHandler(nil, AdamantError(message: "Can't create keypair for passphrase: \(passphrase)"))
			return
		}
		
		completionHandler(keypair.publicKey, nil)
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
