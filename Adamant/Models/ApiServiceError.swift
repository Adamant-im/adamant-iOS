//
//  ApiServiceError.swift
//  Adamant
//
//  Created by Andrey Golubenko on 24.11.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import Foundation
import CommonKit

enum ApiServiceError: LocalizedError, Error {
    case notLogged
    case accountNotFound
    case serverError(error: String)
    case internalError(message: String, error: Error?)
    case networkError(error: Error)
    case requestCancelled
    case commonError(message: String)
    
    var errorDescription: String? {
        switch self {
        case .notLogged:
            return String.adamant.sharedErrors.userNotLogged
            
        case .accountNotFound:
            return String.adamant.sharedErrors.accountNotFound("")
            
        case let .serverError(error):
            return String.adamant.sharedErrors.remoteServerError(message: error)
            
        case let .internalError(msg, error):
            let message = error?.localizedDescription ?? msg
            return String.adamant.sharedErrors.internalError(message: message)
            
        case .networkError(error: _):
            return String.adamant.sharedErrors.networkError
            
        case .requestCancelled:
            return String.adamant.sharedErrors.requestCancelled
            
        case let .commonError(message):
            return String.adamant.sharedErrors.commonError(message)
        }
    }
}

extension ApiServiceError: RichError {
    var message: String {
        localizedDescription
    }
    
    var level: ErrorLevel {
        switch self {
        case .accountNotFound, .notLogged, .networkError, .requestCancelled:
            return .warning
            
        case .serverError, .commonError:
            return .error
            
        case .internalError:
            return .internalError
        }
    }
    
    var internalError: Error? {
        switch self {
        case .accountNotFound, .notLogged, .serverError, .requestCancelled, .commonError:
            return nil
            
        case .internalError(_, let error):
            return error
            
        case .networkError(let error):
            return error
        }
    }
}

extension ApiServiceError: Equatable {
    static func == (lhs: ApiServiceError, rhs: ApiServiceError) -> Bool {
        switch (lhs, rhs) {
        case (.notLogged, .notLogged):
            return true
            
        case (.accountNotFound, .accountNotFound):
            return true
            
        case (.serverError(let le), .serverError(let re)):
            return le == re
            
        case (.internalError(let lm, _), .internalError(let rm, _)):
            return lm == rm
            
        case (.networkError, .networkError):
            return true
            
        default:
            return false
        }
    }
}
