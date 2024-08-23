//
//  InfoServiceApiError.swift
//  Adamant
//
//  Created by Andrew G on 23.08.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import Foundation
import CommonKit

enum InfoServiceApiError: Error {
    case unknown
    case parsingError
    case apiError(ApiServiceError)
}

extension InfoServiceApiError: RichError {
    var message: String {
        switch self {
        case .unknown:
            .adamant.sharedErrors.unknownError
        case .parsingError:
            .localized(
                "ApiService.InternalError.ParsingFailed",
                comment: "Serious internal error: Error parsing response"
            )
        case let .apiError(error):
            error.message
        }
    }
    
    var internalError: Error? {
        switch self {
        case .unknown, .parsingError:
            nil
        case let .apiError(error):
            error
        }
    }
    
    var level: ErrorLevel {
        switch self {
        case .unknown, .parsingError:
            .error
        case let .apiError(error):
            error.level
        }
    }
}
