//
//  BiometryAuthentication.swift
//  Adamant
//
//  Created by Anokhov Pavel on 05.03.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

enum BiometryType {
	case none, touchID, faceID
}

protocol BiometryAuthentication {
	var biometryType: BiometryType { get }
}
