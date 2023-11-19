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
}

extension APICoreProtocol {
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
    
    func sendRequestJson<Parameters: Encodable, JSONOutput: Decodable>(
        node: Node,
        path: String,
        method: HTTPMethod,
        parameters: Parameters,
        encoding: APIParametersEncoding
    ) async -> ApiServiceResult<JSONOutput> {
        switch await sendRequest(
            node: node,
            path: path,
            method: method,
            parameters: parameters,
            encoding: encoding
        ) {
        case let .success(data):
            do {
                let output = try JSONDecoder().decode(JSONOutput.self, from: data)
                return .success(output)
            } catch {
                return .failure(.internalError(error: InternalAPIError.parsingFailed))
            }
        case let .failure(error):
            return .failure(error)
        }
    }
    
    func sendRequestJson<JSONOutput: Decodable>(
        node: Node,
        path: String
    ) async -> ApiServiceResult<JSONOutput> {
        await sendRequestJson(
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
}

private let emptyParameters: [String: Bool] = [:]
