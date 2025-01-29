//
//  APICoreProtocolMock.swift
//  Adamant
//
//  Created by Christian Benua on 09.01.2025.
//  Copyright © 2025 Adamant. All rights reserved.
//

import CommonKit
import Foundation
import Alamofire

final actor APICoreProtocolMock: APICoreProtocol {
    
    var invokedSendRequestMultipartFormData: Bool = false
    var invokedSendRequestMultipartFormDataCount: Int = 0
    var invokedSendRequestMultipartFormDataParameters: (origin: NodeOrigin, path: String, models: [MultipartFormDataModel], timeout: TimeoutSize)?
    var invokedSendRequestMultipartFormDataParametersList: [(origin: NodeOrigin, path: String, models: [MultipartFormDataModel], timeout: TimeoutSize)] = []
    var stubbedSendRequestMultipartFormDataResult: APIResponseModel!
    
    func sendRequestMultipartFormData(
        origin: NodeOrigin,
        path: String,
        models: [MultipartFormDataModel],
        timeout: TimeoutSize,
        uploadProgress: @escaping ((Progress) -> Void)
    ) async -> APIResponseModel {
        invokedSendRequestMultipartFormData = true
        invokedSendRequestMultipartFormDataCount += 1
        invokedSendRequestMultipartFormDataParameters = (origin, path, models, timeout)
        invokedSendRequestMultipartFormDataParametersList.append((origin, path, models, timeout))
        return stubbedSendRequestMultipartFormDataResult
    }
    
    var invokedSendRequestBasicGeneric: Bool = false
    var invokedSendRequestBasicGenericCount: Int = 0
    var invokedSendRequestBasicGenericParameters: (origin: NodeOrigin, path: String, method: HTTPMethod, parameters: Encodable, timeout: TimeoutSize)?
    var invokedSendRequestBasicGenericParametersList: [(origin: NodeOrigin, path: String, method: HTTPMethod, parameters: Encodable, timeout: TimeoutSize)] = []
    var stubbedSendRequestBasicGenericResult: APIResponseModel!
    
    func sendRequestBasic<Parameters: Encodable>(
        origin: NodeOrigin,
        path: String,
        method: HTTPMethod,
        parameters: Parameters,
        encoding: APIParametersEncoding,
        timeout: TimeoutSize,
        downloadProgress: @escaping ((Progress) -> Void)
    ) async -> APIResponseModel {
        invokedSendRequestBasicGeneric = true
        invokedSendRequestBasicGenericCount += 1
        invokedSendRequestBasicGenericParameters = (origin, path, method, parameters, timeout)
        invokedSendRequestBasicGenericParametersList.append((origin, path, method, parameters, timeout))
        
        return stubbedSendRequestBasicGenericResult
    }
    
    var invokedSendRequestBasic: Bool = false
    var invokedSendRequestBasicCount: Int = 0
    var invokedSendRequestBasicParameters: (origin: NodeOrigin, path: String, method: HTTPMethod, jsonParameters: Any, timeout: TimeoutSize)?
    var invokedSendRequestBasicParametersList: [(origin: NodeOrigin, path: String, method: HTTPMethod, jsonParameters: Any, timeout: TimeoutSize)] = []
    var stubbedSendRequestBasicResult: APIResponseModel!
    
    /// jsonParameters - arrays and dictionaries are allowed only
    func sendRequestBasic(
        origin: NodeOrigin,
        path: String,
        method: HTTPMethod,
        jsonParameters: Any,
        timeout: TimeoutSize
    ) async -> APIResponseModel {
        invokedSendRequestBasic = true
        invokedSendRequestBasicCount += 1
        invokedSendRequestBasicParameters = (origin, path, method, jsonParameters, timeout)
        invokedSendRequestBasicParametersList.append((origin, path, method, jsonParameters, timeout))
        
        return stubbedSendRequestBasicResult
    }
}
