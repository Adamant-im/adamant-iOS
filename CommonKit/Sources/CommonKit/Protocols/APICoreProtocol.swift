//
//  APICoreProtocol.swift
//  Adamant
//
//  Created by Andrew G on 30.10.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation
import Alamofire

public enum ApiCommands {}

public enum TimeoutSize: CaseIterable, Hashable {
    case common
    case extended
}

public protocol APICoreProtocol: Actor {
    func sendRequestMultipartFormData(
        origin: NodeOrigin,
        path: String,
        models: [MultipartFormDataModel],
        timeout: TimeoutSize,
        uploadProgress: @escaping ((Progress) -> Void)
    ) async -> APIResponseModel
    
    func sendRequestBasic<Parameters: Encodable>(
        origin: NodeOrigin,
        path: String,
        method: HTTPMethod,
        parameters: Parameters,
        encoding: APIParametersEncoding,
        timeout: TimeoutSize,
        downloadProgress: @escaping ((Progress) -> Void)
    ) async -> APIResponseModel
    
    /// jsonParameters - arrays and dictionaries are allowed only
    func sendRequestBasic(
        origin: NodeOrigin,
        path: String,
        method: HTTPMethod,
        jsonParameters: Any,
        timeout: TimeoutSize
    ) async -> APIResponseModel
}

public extension APICoreProtocol {
    var emptyParameters: [String: Bool] { [:] }
    
    func sendRequest<Parameters: Encodable>(
        origin: NodeOrigin,
        path: String,
        method: HTTPMethod,
        parameters: Parameters,
        encoding: APIParametersEncoding
    ) async -> ApiServiceResult<Data> {
        await sendRequestBasic(
            origin: origin,
            path: path,
            method: method,
            parameters: parameters,
            encoding: encoding,
            timeout: .common,
            downloadProgress: { _ in }
        ).result
    }
    
    func sendRequest<Parameters: Encodable>(
        origin: NodeOrigin,
        path: String,
        method: HTTPMethod,
        parameters: Parameters,
        encoding: APIParametersEncoding,
        timeout: TimeoutSize,
        downloadProgress: @escaping ((Progress) -> Void)
    ) async -> APIResponseModel {
        await sendRequestBasic(
            origin: origin,
            path: path,
            method: method,
            parameters: parameters,
            encoding: encoding,
            timeout: timeout,
            downloadProgress: downloadProgress
        )
    }
    
    func sendRequestJsonResponse<Parameters: Encodable, JSONOutput: Decodable>(
        origin: NodeOrigin,
        path: String,
        method: HTTPMethod,
        parameters: Parameters,
        encoding: APIParametersEncoding
    ) async -> ApiServiceResult<JSONOutput> {
        await sendRequest(
            origin: origin,
            path: path,
            method: method,
            parameters: parameters,
            encoding: encoding
        ).flatMap { parseJSON(data: $0) }
    }
    
    func sendRequestJsonResponse<JSONOutput: Decodable>(
        origin: NodeOrigin,
        path: String
    ) async -> ApiServiceResult<JSONOutput> {
        await sendRequestJsonResponse(
            origin: origin,
            path: path,
            method: .get,
            parameters: emptyParameters,
            encoding: .url
        )
    }
    
    func sendRequest(
        origin: NodeOrigin,
        path: String
    ) async -> ApiServiceResult<Data> {
        await sendRequest(
            origin: origin,
            path: path,
            method: .get,
            parameters: emptyParameters,
            encoding: .url
        )
    }
    
    func sendRequest(
        origin: NodeOrigin,
        path: String,
        timeout: TimeoutSize,
        downloadProgress: @escaping ((Progress) -> Void)
    ) async -> ApiServiceResult<Data> {
        await sendRequest(
            origin: origin,
            path: path,
            method: .get,
            parameters: emptyParameters,
            encoding: .url,
            timeout: timeout,
            downloadProgress: downloadProgress
        ).result
    }
    
    func sendRequest(
        origin: NodeOrigin,
        path: String,
        timeout: TimeoutSize,
        downloadProgress: @escaping @Sendable (Progress) -> Void
    ) async -> APIResponseModel {
        await sendRequest(
            origin: origin,
            path: path,
            method: .get,
            parameters: emptyParameters,
            encoding: .url,
            timeout: timeout,
            downloadProgress: downloadProgress
        )
    }
    
    func sendRequestJsonResponse<JSONOutput: Decodable>(
        origin: NodeOrigin,
        path: String,
        method: HTTPMethod,
        jsonParameters: Any
    ) async -> ApiServiceResult<JSONOutput> {
        await sendRequestBasic(
            origin: origin,
            path: path,
            method: method,
            jsonParameters: jsonParameters,
            timeout: .common
        ).result.flatMap { parseJSON(data: $0) }
    }
    
    func sendRequestMultipartFormDataJsonResponse<JSONOutput: Decodable>(
        origin: NodeOrigin,
        path: String,
        models: [MultipartFormDataModel],
        timeout: TimeoutSize,
        uploadProgress: @escaping ((Progress) -> Void)
    ) async -> ApiServiceResult<JSONOutput> {
        await sendRequestMultipartFormData(
            origin: origin,
            path: path,
            models: models,
            timeout: timeout,
            uploadProgress: uploadProgress
        ).result.flatMap { parseJSON(data: $0) }
    }
    
    func sendRequestRPC(
        origin: NodeOrigin,
        path: String,
        requests: [RpcRequest]
    ) async -> ApiServiceResult<[RPCResponseModel]> {
        let parameters: [Any] = requests.compactMap {
            $0.asDictionary()
        }
        
        return await sendRequestJsonResponse(
            origin: origin,
            path: path,
            method: .post,
            jsonParameters: parameters
        )
    }
    
    func sendRequestRPC(
        origin: NodeOrigin,
        path: String,
        request: RpcRequest
    ) async -> ApiServiceResult<RPCResponseModel> {
        await sendRequestJsonResponse(
            origin: origin,
            path: path,
            method: .post,
            jsonParameters: request.asDictionary() ?? [:]
        )
    }
}

private extension APICoreProtocol {
    func parseJSON<JSON: Decodable>(data: Data) -> ApiServiceResult<JSON> {
        do {
            let output = try JSONDecoder().decode(JSON.self, from: data)
            return .success(output)
        } catch {
            return .failure(.internalError(error: InternalAPIError.parsingFailed))
        }
    }
}
