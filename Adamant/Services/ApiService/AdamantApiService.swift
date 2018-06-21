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
				return NSLocalizedString("ApiService.InternalError.EndpointBuildFailed", comment: "Serious internal error: Failed to build endpoint url")
				
			case .signTransactionFailed:
				return NSLocalizedString("ApiService.InternalError.FailedTransactionSigning", comment: "Serious internal error: Failed to sign transaction")
				
			case .parsingFailed:
				return NSLocalizedString("ApiService.InternalError.ParsingFailed", comment: "Serious internal error: Error parsing response")
				
			case .unknownError:
				return NSLocalizedString("ApiService.InternalError.UnknownError", comment: "Unknown internal error")
			}
		}
	}
	
	// MARK: - Dependencies
	
	var adamantCore: AdamantCore!
	
	
	// MARK: - Properties
	
    var apiUrl: URL
    var apiUrls: [String]
	var defaultResponseDispatchQueue = DispatchQueue(label: "com.adamant.response-queue", qos: .utility, attributes: [.concurrent])
	
	
	// MARK: - Initialization
	
	init(apiUrl: URL) {
		self.apiUrl = apiUrl
        self.apiUrls = [apiUrl.absoluteString] // Temp
	}
    
    init(apiUrls: [String]) {
        self.apiUrls = apiUrls
        self.apiUrl = URL(string: apiUrls[0])! // Temp
        
        self.newServerAddress()
    }
    
    func newServerAddress() {
        let randomIndex = Int(arc4random_uniform(UInt32(self.apiUrls.count)))
        let url = self.apiUrls[randomIndex]
        self.apiUrl = URL(string: url)!
        
        self.testServer { (isAlive) in
            if isAlive == false { self.newServerAddress() }
        }
    }
    
    func updateServersList(servers: [String]) {
        self.apiUrls = servers
        self.newServerAddress()
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
	
	func buildUrl(url: URL, subpath: String, queryItems: [URLQueryItem]? = nil) throws -> URL {
		guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
			throw ApiServiceError.internalError(message: "Failed to build URL from \(url)", error: nil)
		}
		
		components.path = subpath
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
    
    // Test current server is it alive or not
    func testServer(completion: @escaping (Bool) -> Void) {
        // MARK: 1. Build endpoint
        let endpoint: URL
        do {
            endpoint = try buildUrl(path: ApiCommands.Accounts.newAccount)
        } catch {
            completion(false)
            return
        }
        
        let headers = [
            "Content-Type": "application/json"
        ]
        
        // MARK: 2. Send
        sendRequest(url: endpoint, method: .post, encoding: .json, headers: headers) { (serverResponse: ApiServiceResult<ServerModelResponse<Account>>) in
            switch serverResponse {
            case .success: completion(true)
            case .failure: completion(false)
            }
        }
    }
}
