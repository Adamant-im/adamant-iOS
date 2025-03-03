//
//  AdamantAuthentication.swift
//  Adamant
//
//  Created by Anokhov Pavel on 05.03.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import LocalAuthentication

final class AdamantAuthentication: LocalAuthentication {
    var biometryType: BiometryType {
        let context = LAContext()
        var error: NSError?
        let available: Bool
        
        available = context.canEvaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            error: &error
        )
        if available || error?.code == LAError.biometryLockout.rawValue {
            switch context.biometryType {
            case .none, .opticID:
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
    
    func authorizeUser(reason: String) async -> AuthenticationResult {
        let context = LAContext()
        let result = await authorizeUser(
            context: context,
            policy: .deviceOwnerAuthenticationWithBiometrics,
            reason: reason
        )
        if result == .biometryLockout {
            return await authorizeUser(
                context: context,
                policy: .deviceOwnerAuthentication,
                reason: reason
            )
        }
        return result
    }
    
    private func authorizeUser(
        context: LAContext,
        policy: LAPolicy,
        reason: String
    ) async -> AuthenticationResult {
        do {
            let result = try await context.evaluatePolicy(policy, localizedReason: reason)
            if result {
                return .success
            }
        } catch let error as LAError {
            switch error.code {
            case .userFallback:
                return .fallback
            case .biometryLockout:
                return .biometryLockout
            case .userCancel:
                return .cancel
            default:
                return .failed
            }
        } catch {
            return .failed
        }
        return .failed
    }
}
