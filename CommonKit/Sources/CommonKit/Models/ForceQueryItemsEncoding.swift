//
//  ForceQueryItemsEncoding.swift
//  Adamant
//
//  Created by Andrew G on 18.11.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Alamofire
import Foundation

public struct ForceQueryItemsEncoding: ParameterEncoding {
    public let queryItems: [URLQueryItem]
    
    public func encode(
        _ urlRequest: URLRequestConvertible,
        with parameters: Parameters?
    ) throws -> URLRequest {
        var urlRequest = try urlRequest.asURLRequest()
        
        guard
            let url = urlRequest.url,
            var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
        else {
            throw AFError.parameterEncodingFailed(reason: .missingURL)
        }
        
        urlComponents.queryItems = queryItems
        urlRequest.url = urlComponents.url
        return urlRequest
    }
    
    public init(queryItems: [URLQueryItem]) {
        self.queryItems = queryItems
    }
}
