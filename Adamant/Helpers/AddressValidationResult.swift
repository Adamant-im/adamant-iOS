//
//  AddressValidationResult.swift
//  Adamant
//
//  Created by Anokhov Pavel on 03.08.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

enum AddressValidationResult {
    case valid
    case invalid(description: String?)
    
    var isValid: Bool {
        switch self {
        case .valid:
            return true
        case .invalid:
            return false
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .valid:
            return nil
        case let .invalid(description):
            return description
        }
    }
}
