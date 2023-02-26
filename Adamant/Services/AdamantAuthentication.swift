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
            let lockoutCode = LAError.biometryLockout.rawValue
            
            if errorCode == lockoutCode {
                available = true
            } else {
                available = false
            }
        } else {
            available = false
        }
        
        if available {
            switch context.biometryType {
            case .none:
                return .none
                
            case .touchID:
                return .touchID
                
            case .faceID:
                return .faceID
            @unknown default:
                return .none
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
            
            if error.code == LAError.userCancel {
                completion(.cancel)
                return
            }
            
            let tryDeviceOwner = error.code == LAError.biometryLockout
            
            if tryDeviceOwner {
                context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { (success, error) in
                    let result: AuthenticationResult
                    
                    if success {
                        result = .success
                    } else if let error = error as? LAError, error.code == LAError.userCancel {
                        result = .cancel
                    } else {
                        result = .failed
                    }
                    
                    completion(result)
                }
            } else {
                completion(.failed)
            }
        }
    }
}
