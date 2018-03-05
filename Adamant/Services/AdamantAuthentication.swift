//
//  AdamantAuthentication.swift
//  Adamant
//
//  Created by Anokhov Pavel on 05.03.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import LocalAuthentication

class AdamantAuthentication: LocalAuthentication {
	var biometryType: BiometryType {
		let context = LAContext()
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
	
	func authorizeUser(reason: String, completion: @escaping (AuthenticationResult) -> Void) {
		let context = LAContext()
		context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { (success, error) in
			if success {
				completion(.success)
				return
			}
			
			guard let error = error as? LAError else {
				completion(.failed)
				return
			}
			
			if error.code == LAError.userFallback {
				completion(.fallback)
				return
			}
			
			let tryDeviceOwner: Bool
			
			if #available(iOS 11.0, *) {
				tryDeviceOwner = error.code == LAError.biometryLockout
			} else {
				tryDeviceOwner = error.code == LAError.touchIDLockout
			}
			
			if tryDeviceOwner {
				context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { (success, _) in
					completion(.success)
				}
			} else {
				completion(.failed)
			}
		}
	}
}
