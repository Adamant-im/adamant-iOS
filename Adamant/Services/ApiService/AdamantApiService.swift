//
//  AdamantApiService.swift
//  Adamant
//
//  Created by Anokhov Pavel on 06.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import Alamofire

class AdamantApiService: ApiService {
	// MARK: - Shared constants
	
	struct ApiCommands {
		private init() {}
	}
	
	enum Encoding {
		case url, json
	}
	
	
	// MARK: - Dependencies
	
	var adamantCore: AdamantCore!
	
	
	// MARK: - Properties
	
	let apiUrl: URL
	var defaultResponseDispatchQueue = DispatchQueue(label: "com.adamant.response-queue", qos: .utility, attributes: [.concurrent])
	
	
	// MARK: - Initialization
	
	init(apiUrl: URL) {
		self.apiUrl = apiUrl
	}
	
	
	// MARK: - Tools
	
	func buildUrl(path: String, queryItems: [URLQueryItem]? = nil) throws -> URL {
		guard var components = URLComponents(url: apiUrl, resolvingAgainstBaseURL: false) else {
			throw AdamantError(message: "Internal API error: Can't parse API URL: \(apiUrl)")
		}
		
		components.path = path
		components.queryItems = queryItems
		
		return try components.asURL()
	}
	
	func sendRequest<T: Decodable>(url: URLConvertible,
										   method: HTTPMethod = .get,
										   parameters: [String:Any]? = nil,
										   encoding enc: Encoding = .url,
										   headers: [String:String]? = nil,
										   completionHandler: @escaping (T?, Error?) -> Void) {
		let encoding: ParameterEncoding
		switch enc {
		case .url:
			encoding = URLEncoding.default
		case .json:
			encoding = JSONEncoding.default
		}
		
		Alamofire.request(url, method: method, parameters: parameters, encoding: encoding, headers: headers)
			.response(queue: defaultResponseDispatchQueue, completionHandler: { response in
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
		})
	}
}
