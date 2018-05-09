//
//  AnsApiService.swift
//  Adamant
//
//  Created by Anokhov Pavel on 08.05.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import Alamofire

enum AnsApiServiceResult {
	case success
	case failure(ApiServiceError)
}

class AnsApiService {
	struct ApiCommands {
		static let register = "/api/devices/register"
		
		private init() {}
	}
	
	// MARK: Properties
	
	let ansApi: URL
	var defaultResponseDispatchQueue = DispatchQueue(label: "com.adamant.ans-queue", qos: .utility, attributes: [.concurrent])
	
	init(ansApi: URL) {
		self.ansApi = ansApi
	}
	
	func register(token: String, address: String, completion: @escaping (AnsApiServiceResult) -> Void) {
		let parameters: [String: Any] = [
			"token": token,
			"address": address
		]
		
		let headers = [
			"Content-Type": "application/json"
		]
		
		guard var components = URLComponents(url: ansApi, resolvingAgainstBaseURL: false) else {
			fatalError("Parsing API URL failed: \(ansApi)")
		}
		
		components.path = ApiCommands.register
		let url = try! components.asURL()
		
		Alamofire.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers).validate().responseData(queue: defaultResponseDispatchQueue) { response in
			switch response.result {
			case .success:
				completion(.success)
				
			case .failure(let error):
				completion(.failure(.networkError(error: error)))
			}
		}
	}
}
