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
	func newAccount(byPublicKey publicKey: String, completion: @escaping (ApiServiceResult<Account>) -> Void) {
		// MARK: 1. Build endpoint
		let endpoint: URL
		do {
			endpoint = try buildUrl(path: ApiCommands.Accounts.newAccount)
		} catch {
			let err = InternalErrors.endpointBuildFailed.apiServiceErrorWith(error: error)
			completion(.failure(err))
			return
		}
		
		// MARK: 2. Prepare params
		let params = [
			"publicKey": publicKey
		]
		let headers = [
			"Content-Type": "application/json"
		]
		
		// MARK: 3. Send
		sendRequest(url: endpoint, method: .post, parameters: params, encoding: .json, headers: headers) { (serverResponse: ApiServiceResult<ServerModelResponse<Account>>) in
			switch serverResponse {
			case .success(let response):
				if let model = response.model {
					completion(.success(model))
				} else {
					let error = AdamantApiService.translateServerError(response.error)
					completion(.failure(error))
				}
				
			case .failure(let error):
				completion(.failure(.networkError(error: error)))
			}
		}
	}
	
	/// Get existing account by passphrase.
	func getAccount(byPassphrase passphrase: String, completion: @escaping (ApiServiceResult<Account>) -> Void) {
		// MARK: 1. Get keypair from passphrase
		guard let keypair = adamantCore.createKeypairFor(passphrase: passphrase) else {
			completion(.failure(.accountNotFound))
			return
		}
		
		// MARK: 2. Send
		getAccount(byPublicKey: keypair.publicKey, completion: completion)
	}
	
	/// Get existing account by publicKey
	func getAccount(byPublicKey publicKey: String, completion: @escaping (ApiServiceResult<Account>) -> Void) {
		// MARK: 1. Build endpoint
		let endpoint: URL
		do {
			endpoint = try buildUrl(path: ApiCommands.Accounts.root, queryItems: [URLQueryItem(name: "publicKey", value: publicKey)])
		} catch {
			let err = InternalErrors.endpointBuildFailed.apiServiceErrorWith(error: error)
			completion(.failure(err))
			return
		}
		
		// MARK: 2. Send
		sendRequest(url: endpoint) { (serverResponse: ApiServiceResult<ServerModelResponse<Account>>) in
			switch serverResponse {
			case .success(let response):
				if let model = response.model {
					completion(.success(model))
				} else {
					let err = AdamantApiService.translateServerError(response.error)
					completion(.failure(err))
				}
				
			case .failure(let error):
				completion(.failure(.networkError(error: error)))
			}
		}
	}
	
	func getAccount(byAddress address: String, completion: @escaping (ApiServiceResult<Account>) -> Void) {
		// MARK: 1. Build endpoint
		let endpoint: URL
		do {
			endpoint = try buildUrl(path: ApiCommands.Accounts.root, queryItems: [URLQueryItem(name: "address", value: address)])
		} catch {
			let err = InternalErrors.endpointBuildFailed.apiServiceErrorWith(error: error)
			completion(.failure(err))
			return
		}
		
		// MARK: 2. Send
		sendRequest(url: endpoint) { (serverResponse: ApiServiceResult<ServerModelResponse<Account>>) in
			switch serverResponse {
			case .success(let response):
				if let model = response.model {
					completion(.success(model))
				} else {
					let error = AdamantApiService.translateServerError(response.error)
					completion(.failure(error))
				}
				
			case .failure(let error):
				completion(.failure(.networkError(error: error)))
			}
		}
	}
}
