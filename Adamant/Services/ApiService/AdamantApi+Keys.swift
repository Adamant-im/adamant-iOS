//
//  AdamantApi+Keys.swift
//  Adamant
//
//  Created by Anokhov Pavel on 24.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

extension AdamantApiService {
	func getPublicKey(byAddress address: String, completion: @escaping (ApiServiceResult<String>) -> Void) {
		// MARK: 1. Build endpoint
		let endpoint: URL
		do {
			endpoint = try buildUrl(path: ApiCommands.Accounts.getPublicKey, queryItems: [URLQueryItem(name: "address", value: address)])
		} catch {
			let err = InternalErrors.endpointBuildFailed.apiServiceErrorWith(error: error)
			completion(.failure(err))
			return
		}
		
		// MARK: 2. Send
		sendRequest(url: endpoint) { (serverResponse: ApiServiceResult<GetPublicKeyResponse>) in
			switch serverResponse {
			case .success(let response):
				if let publicKey = response.publicKey {
					completion(.success(publicKey))
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
