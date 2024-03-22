//
//  FileManagerError.swift
//  
//
//  Created by Stanislav Jelezoglo on 06.03.2024.
//

import Foundation

public enum FileManagerError: Error {
    case cantDownloadFile
    case cantUploadFile
    case cantEnctryptFile
}

extension FileManagerError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .cantDownloadFile:
            return "cant Download File"
        case .cantUploadFile:
            return "cant Upload File"
        case .cantEnctryptFile:
            return "cant encrypt file"
        }
    }
}
