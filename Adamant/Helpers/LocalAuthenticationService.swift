//
//  LocalAuthenticationHandler.swift
//  Adamant
//
//  Created by Brian on 27/01/2025.
//  Copyright © 2025 Adamant. All rights reserved.
//

import UIKit

protocol LocalAuthenticationService {
    func didEnter(pin: String, pinpadRequest: inout SecurityViewController.PinpadRequest, viewController: UIViewController)
    func didTapBiometryButton(pinpadRequest: SecurityViewController.PinpadRequest, viewController: UIViewController)
    func didTapCancel(pinpadRequest: SecurityViewController.PinpadRequest, viewController: UIViewController)
}

final class LocalAuthenticationServiceImpl: LocalAuthenticationService {
    
    let accountService: AccountService
    let localAuth: LocalAuthentication
    
    init(accountService: AccountService, localAuth: LocalAuthentication) {
        self.accountService = accountService
        self.localAuth = localAuth
    }
    
    func didEnter(pin: String, pinpadRequest: inout SecurityViewController.PinpadRequest, viewController: UIViewController) {
        switch pinpadRequest {
            
        // MARK: User has entered new pin first time. Request re-enter pin
        case .createPin:
            pinpadRequest = .reenterPin(pin: pin)
//            pinpad.commentLabel.text = String.adamant.pinpad.reenterPin
//            pinpad.clearPin()
            return
            
        // MARK: User has reentered pin. Save pin.
        case .reenterPin(let pinToVerify):
            guard pin == pinToVerify else {
//                pinpad.playWrongPinAnimation()
//                pinpad.clearPin()
                break
            }
            
            let result = accountService.setStayLoggedIn(pin: pin)
            Task { @MainActor in
                switch result {
                case .success: return
//                    self.pinpadRequest = nil
//                    if let row: SwitchRow = self.form.rowBy(tag: Rows.biometry.tag) {
//                        row.value = false
//                        row.updateCell()
//                        row.evaluateHidden()
//                    }
                    
//                    if let section = self.form.sectionBy(tag: Sections.notifications.tag) {
//                        section.evaluateHidden()
//                    }
                    
//                    if let section = self.form.sectionBy(tag: Sections.aboutNotificationTypes.tag) {
//                        section.evaluateHidden()
//                    }
                    
//                    pinpad.dismiss(animated: true, completion: nil)
                    
                case .failure(let error): return
//                    self.dialogService.showRichError(error: error)
                }
            }
            
        // MARK: Users want to turn off the pin. Validate and turn off.
        case .turnOffPin:
            guard accountService.validatePin(pin) else {
//                pinpad.playWrongPinAnimation()
//                pinpad.clearPin()
                break
            }
            
            accountService.dropSavedAccount()
            
//            pinpad.dismiss(animated: true, completion: nil)
            
        // MARK: User wants to turn on biometry
        case .turnOnBiometry:
            guard accountService.validatePin(pin) else {
//                pinpad.playWrongPinAnimation()
//                pinpad.clearPin()
                break
            }
            
            accountService.updateUseBiometry(true)
//            pinpad.dismiss(animated: true, completion: nil)
            
        // MARK: User wants to turn off biometry
        case .turnOffBiometry:
            guard accountService.validatePin(pin) else {
//                pinpad.playWrongPinAnimation()
//                pinpad.clearPin()
                break
            }
            
            accountService.updateUseBiometry(false)
//            pinpad.dismiss(animated: true, completion: nil)
            
        default: return
//            pinpad.dismiss(animated: true, completion: nil)
        }

    }
    
    func didTapBiometryButton(pinpadRequest: SecurityViewController.PinpadRequest, viewController: UIViewController) {
        Task {
            switch pinpadRequest {
                // MARK: User wants to turn of StayIn with his face. Or finger.
            case .turnOffPin:
                let result = await localAuth.authorizeUser(reason: String.adamant.security.stayInTurnOff)
                switch result {
                case .success:
                    self.accountService.dropSavedAccount()
                    
//                    if let row: SwitchRow = self.form.rowBy(tag: Rows.biometry.tag) {
//                        row.value = false
//                        row.updateCell()
//                        row.evaluateHidden()
//                    }
                    
//                    if let row = self.form.rowBy(tag: Rows.notifications.tag) {
//                        row.evaluateHidden()
//                    }
                    
//                    pinpad.dismiss(animated: true, completion: nil)
                    
                case .cancel: break
                case .fallback: break
                case .failed: break
                case .biometryLockout: break
                }
            default:
                return
            }
        }
    }
    
    func didTapCancel(pinpadRequest: SecurityViewController.PinpadRequest, viewController: UIViewController) {
//        MainActor.assumeIsolatedSafe {
            switch pinpadRequest {
                
            // MARK: User canceled turning on StayIn
            case .createPin, .reenterPin(pin: _):
                return
//                if let row: SwitchRow = form.rowBy(tag: Rows.stayIn.tag) {
//                    row.value = false
//                    row.updateCell()
//                }
                
            // MARK: User canceled turning off StayIn
            case .turnOffPin:
//                if let row: SwitchRow = form.rowBy(tag: Rows.stayIn.tag) {
//                    row.value = true
//                    row.updateCell()
//                }
                return
            // MARK: User canceled Biometry On
            case .turnOnBiometry:
//                if let row: SwitchRow = form.rowBy(tag: Rows.biometry.tag) {
//                    row.value = false
//                    row.updateCell()
//                }
                return
            // MARK: User canceled Biometry Off
            case .turnOffBiometry:
//                if let row: SwitchRow = form.rowBy(tag: Rows.biometry.tag) {
//                    row.value = true
//                    row.updateCell()
//                }
                return
            default:
                break
            }
            
//            pinpadRequest = nil
//            pinpad.dismiss(animated: true, completion: nil)
//        }
    }
}

