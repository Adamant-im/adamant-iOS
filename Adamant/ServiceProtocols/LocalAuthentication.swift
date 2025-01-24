//
//  LocalAuthentication.swift
//  Adamant
//
//  Created by Anokhov Pavel on 05.03.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

enum BiometryType {
    case none, touchID, faceID
    
    var localized: String {
        switch self {
        case .none: return "None"
        case .touchID: return "Touch ID"
        case .faceID: return "Face ID"
        }
    }
}

enum AuthenticationResult {
    case success
    case biometryLockout
    case cancel
    case fallback
    case failed
}

protocol LocalAuthentication: AnyObject {
    var biometryType: BiometryType { get }
    
    func authorizeUser(reason: String) async -> AuthenticationResult
}
