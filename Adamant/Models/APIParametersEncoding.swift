//
//  APIParametersEncoding.swift
//  Adamant
//
//  Created by Andrew G on 30.10.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Alamofire
import Foundation

enum APIParametersEncoding {
    case url
    case json
    case bodyString
    case forceQueryItems([URLQueryItem])
    
    var parametersEncoding: ParameterEncoding {
        switch self {
        case .url:
            return URLEncoding.default
        case .json:
            return JSONEncoding.default
        case .bodyString:
            return BodyStringEncoding()
        case let .forceQueryItems(items):
            return ForceQueryItemsEncoding(queryItems: items)
        }
    }
}
