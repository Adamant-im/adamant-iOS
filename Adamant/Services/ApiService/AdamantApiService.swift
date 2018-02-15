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
	
	enum InternalError: Error {
		case endpointBuildFailed
		case signTransactionFailed
		case parsingFailed
		case unknownError
		
		func apiServiceErrorWith(error: Error?) -> ApiServiceError {
			return .internalError(message: self.localized, error: error)
		}
		
		var localized: String {
			switch self {
			case .endpointBuildFailed:
				return NSLocalizedString("apiService.endpoint-failed", comment: "Failed to build endpoint url")
				
			case .signTransactionFailed:
				return NSLocalizedString("apiService.failed-signing", comment: "Failed to sign transaction")
				
			case .parsingFailed:
				return NSLocalizedString("apiService.parsing-failed", comment: "Error parsing response")
				
			case .unknownError:
				return NSLocalizedString("apiService.unknown-error", comment: "Unknown error")
			}
		}
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
			fatalError("Parsing API URL failed: \(apiUrl)")
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
								   completion: @escaping (ApiServiceResult<T>) -> Void) {
		let encoding: ParameterEncoding
		switch enc {
		case .url:
			encoding = URLEncoding.default
		case .json:
			encoding = JSONEncoding.default
		}
		
		Alamofire.request(url, method: method, parameters: parameters, encoding: encoding, headers: headers)
			.responseData(queue: defaultResponseDispatchQueue) { response in
				switch response.result {
				case .success(let data):
					do {
						let model: T = try JSONDecoder().decode(T.self, from: data)
						completion(.success(model))
					} catch {
						completion(.failure(InternalError.parsingFailed.apiServiceErrorWith(error: error)))
					}
					
				case .failure(let error):
					completion(.failure(.networkError(error: error)))
				}
		}
	}
	
	static func translateServerError(_ error: String?) -> ApiServiceError {
		guard let error = error else {
			return InternalError.unknownError.apiServiceErrorWith(error: nil)
		}
		
		switch error {
		case "Account not found":
			return .accountNotFound
			
		default:
			return .serverError(error: error)
		}
	}
}
