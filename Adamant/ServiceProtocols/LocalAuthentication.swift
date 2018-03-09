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
}

enum AuthenticationResult {
	case success
	case cancel
	case fallback
	case failed
}

protocol LocalAuthentication: class {
	var biometryType: BiometryType { get }
	
	func authorizeUser(reason: String, completion: @escaping (AuthenticationResult) -> Void)
}
