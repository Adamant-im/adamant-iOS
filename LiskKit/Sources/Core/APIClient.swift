//
//  APIClient.swift
//  Lisk
//
//  Created by Andrew Barba on 12/26/17.
//

import Foundation

/// Represents an HTTP response
public typealias Response<R: APIResponse> = Result<R>

public enum Result<R: Any> {
    case success(response: R)
    case error(response: APIError)
}

/// Type to represent request body/url options
public typealias RequestOptions = [String: Any]

/// HTTP methods we use
public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

/// Client to send requests to a Lisk node
public struct APIClient {

    // MARK: - Static

    /// Mutable. Default client for all services
    public static var shared = APIClient()

    /// Client that connects to Mainnet
    public static let mainnet = APIClient()

    /// Client that connects to Testnet
    public static let testnet = APIClient(options: .testnet)

    /// Client that connects to Betanet
    public static let betanet = APIClient(options: .betanet)
    
    public struct Service {
        public static let mainnet = APIClient(options: .Service.mainnet)
        public static let testnet = APIClient(options: .Service.testnet)
    }

    struct JSONResponse<R: Decodable>: Decodable {
        let id: String
        let jsonrpc: String
        let result: R
    }
    
    // MARK: - Init

    public init(options: APIOptions = .mainnet) {

        // swiftlint:disable:next force_unwrapping
        self.baseURL = URL(string: "\(options.node.origin)")!

        self.headers = [
            "Accept": options.nethash.contentType,
            "Content-Type": options.nethash.contentType,
            "User-Agent": options.nethash.userAgent,
            "nethash": options.nethash.nethash,
            "version": options.nethash.version,
            "minVersion": options.nethash.minVersion
        ]
    }

    // MARK: - Public

    /// Perform GET request
    @discardableResult
    public func get<R>(path: String, options: Any? = nil, completionHandler: @escaping (Response<R>) -> Void) -> (URLRequest, URLSessionDataTask) {
        return request(.get, path: path, options: options, completionHandler: completionHandler)
    }

    /// Perform POST request
    @discardableResult
    public func post<R>(path: String, options: Any? = nil, completionHandler: @escaping (Response<R>) -> Void) -> (URLRequest, URLSessionDataTask) {
        return request(.post, path: path, options: options, completionHandler: completionHandler)
    }

    /// Perform PUT request
    @discardableResult
    public func put<R>(path: String, options: Any? = nil, completionHandler: @escaping (Response<R>) -> Void) -> (URLRequest, URLSessionDataTask) {
        return request(.put, path: path, options: options, completionHandler: completionHandler)
    }

    /// Perform POST request
    @discardableResult
    public func delete<R>(path: String, options: Any? = nil, completionHandler: @escaping (Response<R>) -> Void) -> (URLRequest, URLSessionDataTask) {
        return request(.delete, path: path, options: options, completionHandler: completionHandler)
    }

    /// Perform request
    @discardableResult
    public func request<R>(_ httpMethod: HTTPMethod, path: String, options: Any?, completionHandler: @escaping (Response<R>) -> Void) -> (URLRequest, URLSessionDataTask) {
        let request = urlRequest(httpMethod, path: path, options: options)
        let task = dataTask(request, completionHandler: completionHandler)
        return (request, task)
    }

    public func request<R: Decodable>(
        _ httpMethod: HTTPMethod,
        path: String,
        options: Any?
    ) async throws -> R {
        let request = urlRequest(httpMethod, path: path, options: options)
        let response: R = try await dataTask(request)
        return response
    }
    
    public func request<R: Decodable>(
        method: String,
        params: [String: Any]
    ) async throws -> R {
        let request = try createRPCRequest(method: method, params: params)
        let response: R = try await dataTask(request)
        return response
    }
    
    // MARK: - Private

    /// Base url of all requests
    internal let baseURL: URL

    private let rpcPath = "rpc"

    /// Headers to send on every request
    private let headers: [String: String]

    /// Session to send http requests
    private let urlSession = URLSession(configuration: .ephemeral)

    /// Create a json data task
    private func dataTask<R: Decodable>(_ request: URLRequest) async throws -> R {
        let data = try await urlSession.data(for: request)
        let response: R = try processRequestCompletion(data.0, response: data.1)
        return response
    }
    
    /// Create a json data task
    private func dataTask<R>(_ request: URLRequest, completionHandler: @escaping (Response<R>) -> Void) -> URLSessionDataTask {
        let task = urlSession.dataTask(with: request) { data, response, _ in
            let response: Response<R> = self.processRequestCompletion(data, response: response)
            DispatchQueue.main.async { completionHandler(response) }
        }
        task.resume()
        return task
    }

    /// Builds a URL request based on a given HTTP method and options
    private func urlRequest(_ httpMethod: HTTPMethod, path: String, options: Any? = nil) -> URLRequest {
        // Build api url
        let url = path.contains("://") ? URL(string: path)! : baseURL.appendingPathComponent(path)

        // Build request object
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData)

        // Apply request headers
        for (header, value) in headers {
            request.addValue(value, forHTTPHeaderField: header)
        }

        // Method
        request.httpMethod = httpMethod.rawValue

        // Parse options, apply to body or url based on method
        if let options = options {
            switch httpMethod {
            case .get, .delete:
                request.url = URL(string: url.absoluteString + "?" + urlEncodedQueryString(options))
            case .post, .put:
                request.httpBody = try? JSONSerialization.data(withJSONObject: options, options: [])
            }
        }
        return request
    }

    func createRPCRequest(
        method: String,
        params: [String: Any]
    ) throws -> URLRequest {
        let url = baseURL.appendingPathComponent(rpcPath)
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData)
        
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "jsonrpc": "2.0",
            "id": "1",
            "method": method,
            "params": params
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
        request.httpBody = jsonData
        return request
    }
    /// Converts a dict to url encoded query string
    private func urlEncodedQueryString(_ options: Any) -> String {
        guard let options = options as? RequestOptions else {
            return ""
        }

        let queryParts: [String] = options.compactMap { key, value in
            guard
                let safeKey = key.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed),
                let safeValue = "\(value)".addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
                else { return nil }
            return "\(safeKey)=\(safeValue)"
        }

        return queryParts.joined(separator: "&")
    }

    /// Process a response
    private func processRequestCompletion<R>(
        _ data: Data?,
        response: URLResponse?
    ) -> Response<R> {
        let code = (response as? HTTPURLResponse)?.statusCode
        
        guard let data = data else {
            return .error(response: .unexpected(code: code))
        }

        guard let result = try? JSONDecoder().decode(R.self, from: data) else {
            if var error = try? JSONDecoder().decode(APIError.self, from: data) {
                error.code = code
                return .error(response: error)
            } else if
                let error = try? JSONDecoder().decode(APIErrors.self, from: data),
                var first = error.errors.first
            {
                first.code = code
                return .error(response: first)
            }
            return .error(response: .unknown(code: code))
        }

        return .success(response: result)
    }
    
    /// Process a response
    private func processRequestCompletion<R: Decodable>(
        _ data: Data?,
        response: URLResponse?
    ) throws -> R {
        let code = (response as? HTTPURLResponse)?.statusCode
        
        guard let data = data else {
            throw APIError.unexpected(code: code)
        }

        do {
             if let jsonResponse = try? JSONDecoder().decode(JSONResponse<R>.self, from: data) {
                 return jsonResponse.result
             } else if let result = try? JSONDecoder().decode(R.self, from: data) {
                 return result
             } else if var error = try? JSONDecoder().decode(APIError.self, from: data) {
                 error.code = code
                 throw error
             } else if let error = try? JSONDecoder().decode(APIErrors.self, from: data), var first = error.errors.first {
                 first.code = code
                 throw first
             } else {
                 throw APIError.unknown(code: code)
             }
         } catch {
             throw error
         }
        
    }
}
