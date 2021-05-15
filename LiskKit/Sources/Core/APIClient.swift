//
//  APIClient.swift
//  Lisk
//
//  Created by Andrew Barba on 12/26/17.
//

import Foundation

/// Represents an HTTP response
public enum Response<R: APIResponse> {
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

    // MARK: - Init

    public init(options: APIOptions = .mainnet) {

        // swiftlint:disable:next force_unwrapping
        self.baseURL = URL(string: "\(options.node.origin)/api")!

        self.headers = [
            "Accept": options.nethash.contentType,
            "Content-Type": options.nethash.contentType,
            "User-Agent": options.nethash.userAgent,
            "nethash": options.nethash.nethash,
            "version": options.nethash.version,
            "minVersion": options.nethash.minVersion,
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

    // MARK: - Private

    /// Base url of all requests
    internal let baseURL: URL

    /// Headers to send on every request
    private let headers: [String: String]

    /// Session to send http requests
    private let urlSession = URLSession(configuration: .ephemeral)

    /// Create a json data task
    private func dataTask<R>(_ request: URLRequest, completionHandler: @escaping (Response<R>) -> Void) -> URLSessionDataTask {
        let task = urlSession.dataTask(with: request) { data, _, _ in
            let response: Response<R> = self.processRequestCompletion(data)
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
    private func processRequestCompletion<R>(_ data: Data?) -> Response<R> {
        guard let data = data else {
            return .error(response: .unexpected)
        }

        guard let result = try? JSONDecoder().decode(R.self, from: data) else {
            let error = try? JSONDecoder().decode(APIError.self, from: data)
            return .error(response: error ?? .unknown)
        }

        return .success(response: result)
    }
}
