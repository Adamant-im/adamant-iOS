//
//  AdamantApi+Accounts.swift
//  Adamant
//
//  Created by Anokhov Pavel on 24.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

extension AdamantApiService.ApiCommands {
	static let Accounts = (
		root: "/api/accounts",
		getPublicKey: "/api/accounts/getPublicKey",
		newAccount: "/api/accounts/new"
	)
}

// MARK: - Accounts
extension AdamantApiService {
	
	/// Create new account with publicKey
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
		let headers = [
			"Content-Type": "application/json"
		]
		
		sendRequest(url: endpoint, method: .post, parameters: params, encoding: .json, headers: headers, completionHandler: { (response: ServerModelResponse<Account>?, error) in
			guard let r = response, r.success, let account = r.model else {
				completionHandler(nil, AdamantError(message: response?.error ?? "Failed to create account", error: error))
				return
			}
			
			completionHandler(account, nil)
		})
	}
	
	/// Get existing account by passphrase.
	func getAccount(byPassphrase passphrase: String, completionHandler: @escaping (Account?, AdamantError?) -> Void) {
		guard let keypair = adamantCore.createKeypairFor(passphrase: passphrase) else {
			completionHandler(nil, AdamantError(message: "Can't get account by passphrase: \(passphrase)"))
			return
		}
		
		getAccount(byPublicKey: keypair.publicKey, completionHandler: completionHandler)
	}
	
	/// Get existing account by publicKey
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
