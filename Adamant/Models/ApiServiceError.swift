//
//  ApiServiceError.swift
//  Adamant
//
//  Created by Andrey Golubenko on 24.11.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import Foundation

enum ApiServiceError: LocalizedError, Error {
    case notLogged
    case accountNotFound
    case serverError(error: String)
    case internalError(message: String, error: Error?)
    case networkError(error: Error)
    case requestCancelled
    case baseError(message: String)
    
    var errorDescription: String? {
        switch self {
        case .notLogged:
            return String.adamantLocalized.sharedErrors.userNotLogged
            
        case .accountNotFound:
            return String.adamantLocalized.sharedErrors.accountNotFound("")
            
        case let .serverError(error):
            return String.adamantLocalized.sharedErrors.remoteServerError(message: error)
            
        case let .internalError(msg, error):
            let message = error?.localizedDescription ?? msg
            return String.adamantLocalized.sharedErrors.internalError(message: message)
            
        case .networkError(error: _):
            return String.adamantLocalized.sharedErrors.networkError
            
        case .requestCancelled:
            return String.adamantLocalized.sharedErrors.requestCancelled
            
        case let .baseError(message):
            return String.adamantLocalized.sharedErrors.baseError(message)
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
            
        case .serverError, .baseError:
            return .error
            
        case .internalError:
            return .internalError
        }
    }
    
    var internalError: Error? {
        switch self {
        case .accountNotFound, .notLogged, .serverError, .requestCancelled, .baseError:
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
