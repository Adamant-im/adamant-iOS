//
//  FileValidationError.swift
//  
//
//  Created by Stanislav Jelezoglo on 11.04.2024.
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
            return String.localizedStringWithFormat(.localized(
                "FileValidationError.TooManyFiles",
                comment: "File validation error 'Too many files'"
            ), FilesConstants.maxFilesCount)
        case .fileSizeExceedsLimit:
            return String.localizedStringWithFormat(.localized(
                "FileValidationError.FileSizeExceedsLimit",
                comment: "File validation error 'File size exceeds limit'"
            ), Int(FilesConstants.maxFileSize / (1024 * 1024)))
        case .fileNotFound:
            return .localized("FileValidationError.FileNotFound")
        }
    }
}
