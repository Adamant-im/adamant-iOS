//
//  FileValidationError.swift
//
//
//  Created by Stanislav Jelezoglo on 13.03.2024.
//

import Foundation

public enum FileValidationError: Error {
    case tooManyFiles
    case fileSizeExceedsLimit
    case fileNotFound
}

extension FileValidationError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .tooManyFiles:
            return "too Many Files"
        case .fileSizeExceedsLimit:
            return "file Size Exceeds Limit"
        case .fileNotFound:
            return "file Not Found"
        }
    }
}
