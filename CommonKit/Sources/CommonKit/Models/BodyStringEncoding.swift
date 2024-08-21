//
//  BodyStringEncoding.swift
//  Adamant
//
//  Created by Andrew G on 30.10.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Alamofire
import Foundation

public struct BodyStringEncoding: ParameterEncoding {
    public func encode(
        _ urlRequest: URLRequestConvertible,
        with parameters: Parameters?
    ) throws -> URLRequest {
        var urlRequest = try urlRequest.asURLRequest()
        
        guard
            let string = parameters?.first?.value as? String,
            let data = string.data(using: .utf8)
        else {
            throw AFError.parameterEncodingFailed(
                reason: .customEncodingFailed(error: AdamantError(
                    message: "String encoding problem"
                ))
            )
        }
        
        if parameters?.count != 1 {
            assertionFailure("BodyStringEncoding uses just first parameter for encoding")
        }
        
        urlRequest.httpBody = data
        return urlRequest
    }
}
