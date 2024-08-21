//
//  ApiServiceError+Extension.swift
//  Adamant
//
//  Created by Andrew G on 17.11.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Alamofire
import CommonKit

extension ApiServiceError: RichError {
    var message: String {
        localizedDescription
    }
    
    var level: ErrorLevel {
        switch self {
        case .accountNotFound, .notLogged, .networkError, .requestCancelled, .noEndpointsAvailable:
            return .warning
            
        case .serverError, .commonError:
            return .error
            
        case .internalError:
            return .internalError
        }
    }
    
    var internalError: Error? {
        switch self {
        case .accountNotFound, .notLogged, .serverError, .requestCancelled, .commonError, .noEndpointsAvailable:
            return nil
            
        case .internalError(_, let error):
            return error
            
        case .networkError(let error):
            return error
        }
    }
}
