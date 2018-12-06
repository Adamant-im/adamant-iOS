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
				return String.adamantLocalized.sharedErrors.unknownError
			}
		}
	}
	
	// MARK: - Dependencies
	
	var adamantCore: AdamantCore!
	var nodesSource: NodesSource! {
		didSet {
			refreshNode()
		}
	}
	
	// MARK: - Properties
	
	private(set) var node: Node? {
		didSet {
			currentUrl = node?.asURL()
		}
	}
    
    private var _nodeTimeDelta: TimeInterval?
    private var nodeTimeDeltaSemaphore: DispatchSemaphore = DispatchSemaphore(value: 1)
    
    private(set) var nodeTimeDelta: TimeInterval? {
        get {
            defer { nodeTimeDeltaSemaphore.signal() }
            nodeTimeDeltaSemaphore.wait()
            
            return _nodeTimeDelta
        }
        set {
            nodeTimeDeltaSemaphore.wait()
            _nodeTimeDelta = newValue
            nodeTimeDeltaSemaphore.signal()
        }
    }
    
	private var currentUrl: URL?
	
	let defaultResponseDispatchQueue = DispatchQueue(label: "com.adamant.response-queue", qos: .utility, attributes: [.concurrent])
	
	
	// MARK: - Init
	init() {
		NotificationCenter.default.addObserver(forName: Notification.Name.NodesSource.nodesChanged, object: nil, queue: nil) { [weak self] _ in
			self?.refreshNode()
		}
	}
	
	deinit {
		NotificationCenter.default.removeObserver(self)
	}
	
	
	// MARK: - Tools
	
	func refreshNode() {
		node = nodesSource?.getNewNode()
        
        if let url = currentUrl {
            getNodeVersion(url: url) { result in
                guard case let .success(version) = result else {
                    return
                }
                
                self.nodeTimeDelta = Date().timeIntervalSince(version.nodeDate)
            }
        }
	}
	
	func buildUrl(path: String, queryItems: [URLQueryItem]? = nil) throws -> URL {
		guard let url = currentUrl, var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
			throw InternalError.endpointBuildFailed
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
			.responseData(queue: defaultResponseDispatchQueue) { [weak self] response in
				switch response.result {
				case .success(let data):
					do {
						let model: T = try JSONDecoder().decode(T.self, from: data)
                        
                        if let timestampResponse = model as? ServerResponseWithTimestamp {
                            let nodeDate = AdamantUtilities.decodeAdamant(timestamp: timestampResponse.nodeTimestamp)
                            self?.nodeTimeDelta = Date().timeIntervalSince(nodeDate)
                        }
                        
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
