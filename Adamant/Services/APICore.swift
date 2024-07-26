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
        configuration.timeoutIntervalForRequest = timeoutIntervalForRequest
        configuration.timeoutIntervalForResource = timeoutIntervalForResource
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        return Alamofire.Session.init(configuration: configuration)
    }()
    
    func sendRequestMultipartFormData(
        node: Node,
        path: String,
        models: [MultipartFormDataModel],
        uploadProgress: @escaping ((Progress) -> Void)
    ) async -> APIResponseModel {
        do {
            let request = session.upload(multipartFormData: { multipartFormData in
                models.forEach { file in
                    multipartFormData.append(
                        file.data,
                        withName: file.keyName,
                        fileName: file.fileName
                    )
                }
            }, to: try buildUrl(node: node, path: path))
                .uploadProgress(queue: .global(), closure: uploadProgress)
            
            return await sendRequest(request: request)
        } catch {
            return .init(
                result: .failure(.internalError(message: error.localizedDescription, error: error)),
                data: nil,
                code: nil
            )
        }
    }
    
    func sendRequestBasic<Parameters: Encodable>(
        node: Node,
        path: String,
        method: HTTPMethod,
        parameters: Parameters,
        encoding: APIParametersEncoding,
        downloadProgress: @escaping ((Progress) -> Void)
    ) async -> APIResponseModel {
        do {
            let request = session.request(
                try buildUrl(node: node, path: path),
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
}

private extension APICore {
    func sendRequest(request: DataRequest) async -> APIResponseModel {
        await withCheckedContinuation { continuation in
            request.responseData(queue: responseQueue) { response in
                let code = response.response?.statusCode
                let result: ApiServiceResult<Data>
                
                if let code = code, code == 502 || code == 504 {
                    result = .failure(.serverError(error: "unknown"))
                } else {
                    result = response.result.mapError { .init(error: $0) }
                }
                
                continuation.resume(returning: .init(
                    result: result,
                    data: response.data,
                    code: code
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

private let timeoutIntervalForRequest: TimeInterval = 15
private let timeoutIntervalForResource: TimeInterval = 24 * 3600
