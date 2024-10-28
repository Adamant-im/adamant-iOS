//
//  ApiServiceError.swift
//  Adamant
//
//  Created by Andrey Golubenko on 24.11.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import Foundation

public enum ApiServiceError: LocalizedError, Sendable {
    case notLogged
    case accountNotFound
    case serverError(error: String)
    case internalError(message: String, error: Error?)
    case networkError(error: Error)
    case requestCancelled
    case commonError(message: String)
    case noEndpointsAvailable(nodeGroupName: String)
    
    public var errorDescription: String? {
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
            
        case let .networkError(error):
            return error.localizedDescription
            
        case .requestCancelled:
            return String.adamant.sharedErrors.requestCancelled
            
        case let .commonError(message):
            return String.adamant.sharedErrors.commonError(message)
            
        case let .noEndpointsAvailable(nodeGroupName):
            return .localizedStringWithFormat(
                .localized(
                    "ApiService.InternalError.NoNodesAvailable",
                    comment: "Serious internal error: No nodes available"
                ),
                nodeGroupName
            ).localized
        }
    }
    
    public static func internalError(error: InternalAPIError) -> Self {
        .internalError(message: error.localizedDescription, error: error)
    }
}

extension ApiServiceError: Equatable {
    public static func == (lhs: ApiServiceError, rhs: ApiServiceError) -> Bool {
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

extension ApiServiceError: HealthCheckableError {
    public var isNetworkError: Bool {
        switch self {
        case .networkError:
            return true
        default:
            return false
        }
    }
    
    public static var noNetworkError: ApiServiceError {
        .networkError(error: AdamantError(message: .adamant.sharedErrors.networkError))
    }
    
    public static func noEndpointsError(nodeGroupName: String) -> ApiServiceError {
        .noEndpointsAvailable(nodeGroupName: nodeGroupName)
    }
}
