//
//  AdamantAuthentication.swift
//  Adamant
//
//  Created by Anokhov Pavel on 05.03.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import LocalAuthentication

class AdamantAuthentication: BiometryAuthentication {
	private let context = LAContext()
	
	var biometryType: BiometryType {
		var error: NSError?
		let available: Bool
		
		if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
			available = true
		} else if let errorCode = error?.code {
			let lockoutCode: Int
			if #available(iOS 11.0, *) {
				lockoutCode = LAError.biometryLockout.rawValue
			} else {
				lockoutCode = LAError.touchIDLockout.rawValue
			}
			
			if errorCode == lockoutCode {
				available = true
			} else {
				available = false
			}
		} else {
			available = false
		}
		
		if available {
			if #available(iOS 11.0, *) {
				switch context.biometryType {
				case .none:
					return .none
					
				case .touchID:
					return .touchID
					
				case .faceID:
					return .faceID
				}
			} else {
				return .touchID
			}
		} else {
			return .none
		}
	}
}
