//
//  FileManagerError.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 10.04.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import Foundation

enum NetworkFileProtocolType: String {
    case ipfs
}

enum FileManagerError: Error {
    case cantDownloadFile
    case cantUploadFile
    case cantEnctryptFile
}

extension FileManagerError: LocalizedError {
    var errorDescription: String? {
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
