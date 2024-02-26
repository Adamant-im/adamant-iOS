//
//  FileValidationError.swift
//
//
//  Created by Stanislav Jelezoglo on 12.02.2024.
//

import Foundation

public enum FileValidationError: Error, LocalizedError {
    case tooManyFiles
    case fileSizeExceedsLimit
    case fileNotFound
    
    public var errorDescription: String {
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

public enum FileManagerError: Error, LocalizedError {
    case cantDownloadFile
    case cantUploadFile
    
    public var errorDescription: String {
        switch self {
        case .cantDownloadFile:
            return "cant Download File"
        case .cantUploadFile:
            return "cant Upload File"
        }
    }
}
