//
//  AdamantApi+Keys.swift
//  Adamant
//
//  Created by Anokhov Pavel on 24.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

extension AdamantApiService {
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
