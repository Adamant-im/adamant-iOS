//
//  ApiServiceError+Extension.swift
//  Adamant
//
//  Created by Andrew G on 17.11.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Alamofire

extension ApiServiceError {
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
