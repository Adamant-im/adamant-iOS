//
//  APICore.swift
//  Adamant
//
//  Created by Andrew G on 30.10.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation
import Alamofire
import CommonKit

actor APICore: APICoreProtocol {
    private let responseQueue = DispatchQueue(
        label: "com.adamant.response-queue",
        qos: .userInteractive
    )
    
    private lazy var session: Session = {
        let configuration = AF.sessionConfiguration
        configuration.waitsForConnectivity = true
        configuration.timeoutIntervalForRequest = timeoutInterval
        configuration.timeoutIntervalForResource = timeoutInterval
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        return Alamofire.Session.init(configuration: configuration)
    }()
    
    func sendRequestBasic<Parameters: Encodable>(
        node: Node,
        path: String,
        method: HTTPMethod,
        parameters: Parameters,
        encoding: APIParametersEncoding
    ) async -> APIResponseModel {
        do {
            let request = session.request(
                try buildUrl(node: node, path: path),
                method: method,
                parameters: parameters.asDictionary(),
                encoding: encoding.parametersEncoding,
                headers: HTTPHeaders(["Content-Type": "application/json"])
            )
            
            return await sendRequest(request: request)
        } catch {
            return .init(
                result: .failure(.internalError(message: error.localizedDescription, error: error)),
                data: nil,
                code: nil
            )
        }
    }
    
    func sendRequestBasic(
        node: Node,
        path: String,
        method: HTTPMethod,
        jsonParameters: Any
    ) async -> APIResponseModel {
        do {
            let data = try JSONSerialization.data(
                withJSONObject: jsonParameters
            )
            
            var request = try URLRequest(
                url: try buildUrl(node: node, path: path),
                method: method
            )
            
            request.httpBody = data
            request.headers.update(.contentType("application/json"))
            return await sendRequest(request: AF.request(request))
        } catch {
            return .init(
                result: .failure(.internalError(message: error.localizedDescription, error: error)),
                data: nil,
                code: nil
            )
        }
    }
    
    func sendRequestRPC(
        node: Node,
        path: String,
        methods: [String]
    ) async -> APIResponseModel {
        do {
            var body: [[String: Any]] = []
            methods.forEach { method in
                let requestBody: [String: Any] = [
                    "jsonrpc": "2.0",
                    "id": method,
                    "method": method,
                    "params": []
                ]
                
                body.append(requestBody)
            }
            
            let data = try JSONSerialization.data(withJSONObject: body)
            
            var request = try URLRequest(
                url: try buildUrl(node: node, path: path),
                method: .post
            )
            
            request.httpBody = data
            request.headers.update(.contentType("application/json"))
            return await sendRequest(request: AF.request(request))
        } catch {
            return .init(
                result: .failure(.internalError(message: error.localizedDescription, error: error)),
                data: nil,
                code: nil
            )
        }
    }
}

private extension APICore {
    func sendRequest(request: DataRequest) async -> APIResponseModel {
        await withCheckedContinuation { continuation in
            request.responseData(queue: responseQueue) { response in
                continuation.resume(returning: .init(
                    result: response.result.mapError { .init(error: $0) },
                    data: response.data,
                    code: response.response?.statusCode
                ))
            }
        }
    }
    
    func buildUrl(node: Node, path: String) throws -> URL {
        guard let url = node.asURL()?.appendingPathComponent(path, conformingTo: .url)
        else { throw InternalAPIError.endpointBuildFailed }
        return url
    }
}

private let timeoutInterval: TimeInterval = 15
