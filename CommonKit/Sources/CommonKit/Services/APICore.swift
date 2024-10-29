//
//  APICore.swift
//  Adamant
//
//  Created by Andrew G on 30.10.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation
@preconcurrency import Alamofire

public actor APICore: APICoreProtocol {
    private let responseQueue = DispatchQueue(
        label: "com.adamant.response-queue",
        qos: .userInteractive
    )
    
    private var sessions: [TimeoutSize: Session] = .init()
    
    public func sendRequestMultipartFormData(
        origin: NodeOrigin,
        path: String,
        models: [MultipartFormDataModel],
        timeout: TimeoutSize,
        uploadProgress: @escaping ((Progress) -> Void)
    ) async -> APIResponseModel {
        do {
            let request = getSession(timeout).upload(
                multipartFormData: { multipartFormData in
                    models.forEach { file in
                        multipartFormData.append(
                            file.data,
                            withName: file.keyName,
                            fileName: file.fileName
                        )
                    }
                },
                to: try buildUrl(origin: origin, path: path)
            ).uploadProgress(queue: .global(), closure: uploadProgress)
            
            return await sendRequest(request: request)
        } catch {
            return .init(
                result: .failure(.internalError(message: error.localizedDescription, error: error)),
                data: nil,
                code: nil
            )
        }
    }
    
    public func sendRequestBasic<Parameters: Encodable>(
        origin: NodeOrigin,
        path: String,
        method: HTTPMethod,
        parameters: Parameters,
        encoding: APIParametersEncoding,
        timeout: TimeoutSize,
        downloadProgress: @escaping ((Progress) -> Void)
    ) async -> APIResponseModel {
        do {
            let request = getSession(timeout).request(
                try buildUrl(origin: origin, path: path),
                method: method,
                parameters: parameters.asDictionary(),
                encoding: encoding.parametersEncoding,
                headers: HTTPHeaders(["Content-Type": "application/json"])
            ).downloadProgress(closure: downloadProgress)
            
            return await sendRequest(request: request)
        } catch {
            return .init(
                result: .failure(.internalError(message: error.localizedDescription, error: error)),
                data: nil,
                code: nil
            )
        }
    }
    
    public func sendRequestBasic(
        origin: NodeOrigin,
        path: String,
        method: HTTPMethod,
        jsonParameters: Any,
        timeout: TimeoutSize
    ) async -> APIResponseModel {
        do {
            let data = try JSONSerialization.data(
                withJSONObject: jsonParameters
            )
            
            var request = try URLRequest(
                url: try buildUrl(origin: origin, path: path),
                method: method
            )
            
            request.httpBody = data
            request.headers.update(.contentType("application/json"))
            return await sendRequest(request: getSession(timeout).request(request))
        } catch {
            return .init(
                result: .failure(.internalError(message: error.localizedDescription, error: error)),
                data: nil,
                code: nil
            )
        }
    }
    
    public init() {}
}

private extension APICore {
    func sendRequest(request: DataRequest) async -> APIResponseModel {
        await withTaskCancellationHandler(
            operation: {
                await withCheckedContinuation { continuation in
                    request.responseData(queue: responseQueue) { response in
                        continuation.resume(returning: .init(
                            result: response.result.mapError { .init(error: $0) },
                            data: response.data,
                            code: response.response?.statusCode
                        ))
                    }
                }
            },
            onCancel: { request.cancel() }
        )
    }
    
    func buildUrl(origin: NodeOrigin, path: String) throws -> URL {
        guard let url = origin.asURL()?.appendingPathComponent(path, conformingTo: .url)
        else { throw InternalAPIError.endpointBuildFailed }
        return url
    }
    
    func getSession(_ timeout: TimeoutSize) -> Session {
        if let session = sessions[timeout] {
            return session
        }
        
        let configuration = AF.sessionConfiguration
        configuration.waitsForConnectivity = true
        configuration.timeoutIntervalForRequest = requestTimeout
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.httpMaximumConnectionsPerHost = maximumConnectionsPerHost
        
        configuration.timeoutIntervalForResource = switch timeout {
        case .common:
            resourceTimeout
        case .extended:
            extendedResourceTimeout
        }
        
        let session = Alamofire.Session.init(configuration: configuration)
        sessions[timeout] = session
        return session
    }
}

private let requestTimeout: TimeInterval = 15
private let resourceTimeout: TimeInterval = 15
private let extendedResourceTimeout: TimeInterval = 24 * 3600
private let maximumConnectionsPerHost = 100
