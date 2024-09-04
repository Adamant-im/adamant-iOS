//
//  ApiServiceError+AFError.swift
//
//
//  Created by Andrew G on 08.08.2024.
//

import Alamofire

public extension ApiServiceError {
    init(error: Error) {
        let afError = error as? AFError
        
        switch afError {
        case .explicitlyCancelled:
            self = .requestCancelled
        default:
            self = .networkError(error: error)
        }
    }
}
