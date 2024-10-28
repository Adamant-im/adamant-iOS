//
//  InfoServiceApiError.swift
//  Adamant
//
//  Created by Andrew G on 23.08.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import Foundation
import CommonKit

enum InfoServiceApiError: Error, Sendable {
    case unknown
    case parsingError
    case inconsistentData
    case apiError(ApiServiceError)
}

extension InfoServiceApiError: RichError {
    var message: String {
        switch self {
        case .unknown:
            .adamant.sharedErrors.unknownError
        case .parsingError:
            .localized("ApiService.InternalError.ParsingFailed")
        case .inconsistentData:
            .localized("InfoService.InconsistentData")
        case let .apiError(error):
            error.message
        }
    }
    
    var internalError: Error? {
        switch self {
        case .unknown, .parsingError, .inconsistentData:
            nil
        case let .apiError(error):
            error
        }
    }
    
    var level: ErrorLevel {
        switch self {
        case .unknown, .parsingError, .inconsistentData:
            .error
        case let .apiError(error):
            error.level
        }
    }
}
