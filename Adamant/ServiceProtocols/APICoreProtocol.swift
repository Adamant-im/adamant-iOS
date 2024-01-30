//
//  APICoreProtocol.swift
//  Adamant
//
//  Created by Andrew G on 30.10.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation
import Alamofire
import CommonKit
import UIKit

enum ApiCommands {}

protocol APICoreProtocol: Actor {
    func sendRequestBasic<Parameters: Encodable>(
        node: Node,
        path: String,
        method: HTTPMethod,
        parameters: Parameters,
        encoding: APIParametersEncoding
    ) async -> APIResponseModel
    
    /// jsonParameters - arrays and dictionaries are allowed only
    func sendRequestBasic(
        node: Node,
        path: String,
        method: HTTPMethod,
        jsonParameters: Any
    ) async -> APIResponseModel
    
    func sendRequestRPC(
        node: Node,
        path: String,
        methods: [String]
    ) async -> APIResponseModel
}

extension APICoreProtocol {
    var emptyParameters: [String: Bool] { [:] }
    
    func sendRequest<Parameters: Encodable>(
        node: Node,
        path: String,
        method: HTTPMethod,
        parameters: Parameters,
        encoding: APIParametersEncoding
    ) async -> ApiServiceResult<Data> {
        await sendRequestBasic(
            node: node,
            path: path,
            method: method,
            parameters: parameters,
            encoding: encoding
        ).result
    }
    
    func sendRequestJsonResponse<Parameters: Encodable, JSONOutput: Decodable>(
        node: Node,
        path: String,
        method: HTTPMethod,
        parameters: Parameters,
        encoding: APIParametersEncoding
    ) async -> ApiServiceResult<JSONOutput> {
        await sendRequest(
            node: node,
            path: path,
            method: method,
            parameters: parameters,
            encoding: encoding
        ).flatMap { parseJSON(data: $0) }
    }
    
    func sendRequestJsonResponse<JSONOutput: Decodable>(
        node: Node,
        path: String
    ) async -> ApiServiceResult<JSONOutput> {
        await sendRequestJsonResponse(
            node: node,
            path: path,
            method: .get,
            parameters: emptyParameters,
            encoding: .url
        )
    }
    
    func sendRequest(
        node: Node,
        path: String
    ) async -> ApiServiceResult<Data> {
        await sendRequest(
            node: node,
            path: path,
            method: .get,
            parameters: emptyParameters,
            encoding: .url
        )
    }
    
    func sendRequestJsonResponse<JSONOutput: Decodable>(
        node: Node,
        path: String,
        method: HTTPMethod,
        jsonParameters: Any
    ) async -> ApiServiceResult<JSONOutput> {
        await sendRequestBasic(
            node: node,
            path: path,
            method: method,
            jsonParameters: jsonParameters
        ).result.flatMap { parseJSON(data: $0) }
    }
    
    func sendRequestRPCArrayResponse(
        node: Node,
        path: String,
        methods: [String]
    ) async -> ApiServiceResult<[String: Data]> {
        await sendRequestRPC(
            node: node, 
            path: path,
            methods: methods
        ).result.flatMap { parseRPCArray(data: $0) }
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
    
    func parseRPCArray(
        data: Data
    ) -> ApiServiceResult<[String: Data]> {
        do {
            var result: [String: Data] = [:]
            let output = try JSONDecoder().decode([RPCResponseModel].self, from: data)
            
            output.forEach { response in
                result[response.id] = response.result
            }
            return .success(result)
        } catch {
            return .failure(.internalError(error: InternalAPIError.parsingFailed))
        }
    }
}
