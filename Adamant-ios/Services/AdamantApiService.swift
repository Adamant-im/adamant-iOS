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
	static let Accounts = "accounts"
	static let Transactions = "transactions"
	
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
		let endpoint = apiUrl.appendingPathComponent("\(ApiCommands.Accounts)?publicKey=\(publicKey.hex)")
		
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
		let endpoint = apiUrl.appendingPathComponent("\(ApiCommands.Transactions)?inId=\(account)&and:type=\(type.rawValue)")
		
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
