//
//  AdamantApiService.swift
//  Adamant-ios
//
//  Created by Павел Анохов on 06.01.2018.
//  Copyright © 2018 adamant. All rights reserved.
//

import Foundation
import Alamofire

class AdamantApiService: ApiService {
	var adamantCore: AdamantCore!
	
	var serverUrl: String!
	
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
		let endpoint = "https://endless.adamant.im/api/accounts?publicKey=\(publicKey.hex)"
		
		sendRequest(url: endpoint) { (responseRaw: AccountsResponse?, error) in
			guard let response = responseRaw, response.success, let account = response.account else {
				completionHandler(nil, AdamantError(message: responseRaw?.error ?? "Failed to get account", error: error))
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
