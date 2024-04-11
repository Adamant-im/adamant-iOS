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
    case cantEncryptFile
    case cantDecryptFile
}

extension FileManagerError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .cantDownloadFile:
            return .localized("FileManagerError.CantDownloadFile")
        case .cantUploadFile:
            return .localized("FileManagerError.CantUploadFile")
        case .cantEncryptFile:
            return .localized("FileManagerError.CantEncryptFile")
        case .cantDecryptFile:
            return .localized("FileManagerError.CantDecryptFile")
        }
    }
}
