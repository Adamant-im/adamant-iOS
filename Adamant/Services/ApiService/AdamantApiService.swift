//
//  AdamantApiService.swift
//  Adamant
//
//  Created by Anokhov Pavel on 06.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
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
        case noNodesAvailable
        
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
            
            case .noNodesAvailable:
                return NSLocalizedString("ApiService.InternalError.NoNodesAvailable", comment: "Serious internal error: No nodes available")
            }
        }
    }
    
    // MARK: - Dependencies
    
    var adamantCore: AdamantCore!
    
    weak var nodesSource: NodesSource? {
        didSet {
            updateCurrentNodes()
        }
    }
    
    // MARK: - Properties
    
    private var _lastRequestTimeDelta: TimeInterval?
    private var lastRequestTimeDeltaSemaphore: DispatchSemaphore = DispatchSemaphore(value: 1)
    
    private(set) var currentNodes: [Node] = [] {
        didSet {
            guard oldValue != currentNodes else { return }
            sendCurrentNodeUpdateNotification()
        }
    }
    
    private(set) var lastRequestTimeDelta: TimeInterval? {
        get {
            defer { lastRequestTimeDeltaSemaphore.signal() }
            lastRequestTimeDeltaSemaphore.wait()
            
            return _lastRequestTimeDelta
        }
        set {
            lastRequestTimeDeltaSemaphore.wait()
            _lastRequestTimeDelta = newValue
            lastRequestTimeDeltaSemaphore.signal()
        }
    }
    
    var sendingMsgTaskId: UIBackgroundTaskIdentifier = UIBackgroundTaskIdentifier.invalid
    
    let defaultResponseDispatchQueue = DispatchQueue(
        label: "com.adamant.response-queue",
        qos: .userInteractive
    )
    
    // MARK: - Init
    
    init() {
        NotificationCenter.default.addObserver(
            forName: Notification.Name.NodesSource.nodesUpdate,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            self?.updateCurrentNodes()
        }
    }
    
    // MARK: - Tools
    
    func buildUrl(node: Node, path: String, queryItems: [URLQueryItem]? = nil) throws -> URL {
        guard let url = node.asURL() else { throw InternalError.endpointBuildFailed }
        return try buildUrl(url: url, path: path, queryItems: queryItems)
    }
    
    func buildUrl(url: URL, path: String, queryItems: [URLQueryItem]? = nil) throws -> URL {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw ApiServiceError.internalError(message: "Failed to build URL from \(url)", error: nil)
        }
        
        components.path = path
        components.queryItems = queryItems
        
        return try components.asURL()
    }
    
    func sendRequest<T: Decodable>(
        path: String,
        queryItems: [URLQueryItem]? = nil,
        method: HTTPMethod = .get,
        parameters: [String: Any]? = nil,
        encoding: Encoding = .url,
        headers: [String: String]? = nil,
        completion: @escaping (ApiServiceResult<T>) -> Void
    ) {
        guard !currentNodes.isEmpty else {
            let error = InternalError.endpointBuildFailed.apiServiceErrorWith(
                error: InternalError.noNodesAvailable
            )
            completion(.failure(error))
            return
        }
        
        sendSafeRequest(
            nodes: currentNodes,
            path: path,
            queryItems: queryItems,
            method: method,
            parameters: parameters,
            encoding: encoding,
            headers: headers,
            onFailure: { [weak self] node in
                node.connectionStatus = .offline
                self?.nodesSource?.nodesUpdate()
            },
            completion: completion
        )
        
        updateCurrentNodes()
    }
    
    /// On failure this method doesn't call completion, it just goes to next node. Completion called on success or on last node failure.
    private func sendSafeRequest<T: Decodable>(
        nodes: [Node],
        path: String,
        queryItems: [URLQueryItem]?,
        method: HTTPMethod,
        parameters: [String: Any]?,
        encoding: Encoding,
        headers: [String: String]?,
        onFailure: @escaping (Node) -> Void,
        completion: @escaping (ApiServiceResult<T>) -> Void
    ) {
        guard let node = nodes.first else {
            let error = InternalError.endpointBuildFailed.apiServiceErrorWith(
                error: InternalError.unknownError
            )
            completion(.failure(error))
            return
        }
        
        let url: URL
        do {
            url = try buildUrl(node: node, path: path, queryItems: queryItems)
        } catch {
            let err = InternalError.endpointBuildFailed.apiServiceErrorWith(error: error)
            completion(.failure(err))
            return
        }
        
        let completion: (ApiServiceResult<T>) -> Void = { [weak self] result in
            switch result {
            case .success:
                completion(result)
            case let .failure(error):
                switch error {
                case .networkError:
                    onFailure(node)
                    var nodes = nodes
                    nodes.removeFirst()
                    self?.sendSafeRequest(
                        nodes: nodes,
                        path: path,
                        queryItems: queryItems,
                        method: method,
                        parameters: parameters,
                        encoding: encoding,
                        headers: headers,
                        onFailure: onFailure,
                        completion: completion
                    )
                case .accountNotFound, .internalError, .notLogged, .serverError, .requestCancelled:
                    completion(result)
                }
            }
        }
        
        sendRequest(
            url: url,
            method: method,
            parameters: parameters,
            encoding: encoding,
            headers: headers,
            completion: completion
        )
    }
    
    @discardableResult
    func sendRequest<T: Decodable>(
        url: URLConvertible,
        method: HTTPMethod = .get,
        parameters: [String: Any]? = nil,
        encoding enc: Encoding = .url,
        headers: [String: String]? = nil,
        completion: @escaping (ApiServiceResult<T>) -> Void
    ) -> DataRequest {
        let encoding: ParameterEncoding
        switch enc {
        case .url:
            encoding = URLEncoding.default
        case .json:
            encoding = JSONEncoding.default
        }
        
        let headers: HTTPHeaders = HTTPHeaders(headers ?? [:])
        
        return AF.request(
            url,
            method: method,
            parameters: parameters,
            encoding: encoding,
            headers: headers
        ).responseData(queue: defaultResponseDispatchQueue) { [weak self] response in
            switch response.result {
            case .success(let data):
                do {
                    let model: T = try JSONDecoder().decode(T.self, from: data)
                    
                    if let timestampResponse = model as? ServerResponseWithTimestamp {
                        let nodeDate = AdamantUtilities.decodeAdamant(timestamp: timestampResponse.nodeTimestamp)
                        self?.lastRequestTimeDelta = Date().timeIntervalSince(nodeDate)
                    }
                    
                    completion(.success(model))
                } catch {
                    completion(.failure(InternalError.parsingFailed.apiServiceErrorWith(error: error)))
                }
                
            case .failure(let error):
                completion(.failure(.init(error: error)))
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
    
    private func updateCurrentNodes() {
        currentNodes = nodesSource?.getAllowedNodes(needWS: false) ?? []
    }
    
    private func sendCurrentNodeUpdateNotification() {
        NotificationCenter.default.post(
            name: Notification.Name.ApiService.currentNodeUpdate,
            object: self,
            userInfo: nil
        )
    }
}

private extension ApiServiceError {
    init(error: Error) {
        let afError = error as? AFError
        
        switch afError {
        case .explicitlyCancelled:
            self = .requestCancelled
        default:
            self = .networkError(error: error)
        }
    }
}
