//
//  BitcoinError.swift
//  
//
//  Created by Andrey Golubenko on 06.06.2023.
//

import Foundation

enum BitcoinError: LocalizedError {
    case unknownAddressType
    case invalidAddressLength
    case invalidChecksum
    case wrongAddressPrefix
    case list(errors: [Error])
    
    var errorDescription: String? {
        switch self {
        case .unknownAddressType:
            return "Unknown address type"
        case .invalidAddressLength:
            return "Invalid address length"
        case .invalidChecksum:
            return "Invalid checksum"
        case .wrongAddressPrefix:
            return "Wrong address prefix"
        case let .list(errors):
            return errors
                .map { $0.localizedDescription }
                .joined(separator: ". ")
        }
    }
}
