//
//  InternalAPIError.swift
//  Adamant
//
//  Created by Andrew G on 30.10.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation

public enum InternalAPIError: LocalizedError {
    case endpointBuildFailed
    case signTransactionFailed
    case parsingFailed
    case unknownError
    
    public func apiServiceErrorWith(error: Error) -> ApiServiceError {
        .internalError(message: localizedDescription, error: error)
    }
    
    public var errorDescription: String? {
        switch self {
        case .endpointBuildFailed:
            return .localized(
                "ApiService.InternalError.EndpointBuildFailed",
                comment: "Serious internal error: Failed to build endpoint url"
            )
        case .signTransactionFailed:
            return .localized(
                "ApiService.InternalError.FailedTransactionSigning",
                comment: "Serious internal error: Failed to sign transaction"
            )
        case .parsingFailed:
            return .localized(
                "ApiService.InternalError.ParsingFailed",
                comment: "Serious internal error: Error parsing response"
            )
        case .unknownError:
            return .adamant.sharedErrors.unknownError
        }
    }
}
