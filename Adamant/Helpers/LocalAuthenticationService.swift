//
//  LocalAuthenticationHandler.swift
//  Adamant
//
//  Created by Brian on 27/01/2025.
//  Copyright © 2025 Adamant. All rights reserved.
//

import UIKit

protocol LocalAuthenticationService {
    func didEnter(pin: String, viewController: UIViewController)
    func didTapBiometryButton(viewController: UIViewController)
    func didTapCancel(viewController: UIViewController)
}

final class LocalAuthenticationHandlerImpl: LocalAuthenticationService {
    
    
    func didEnter(pin: String, viewController: UIViewController) {
        switch pinpadRequest {
            
        // MARK: User has entered new pin first time. Request re-enter pin
        case .createPin?:
            pinpadRequest = .reenterPin(pin: pin)
            pinpad.commentLabel.text = String.adamant.pinpad.reenterPin
            pinpad.clearPin()
            return
            
        // MARK: User has reentered pin. Save pin.
        case .reenterPin(let pinToVerify)?:
            guard pin == pinToVerify else {
                pinpad.playWrongPinAnimation()
                pinpad.clearPin()
                break
            }
            
            let result = accountService.setStayLoggedIn(pin: pin)
            Task { @MainActor in
                switch result {
                case .success:
                    self.pinpadRequest = nil
                    if let row: SwitchRow = self.form.rowBy(tag: Rows.biometry.tag) {
                        row.value = false
                        row.updateCell()
                        row.evaluateHidden()
                    }
                    
                    if let section = self.form.sectionBy(tag: Sections.notifications.tag) {
                        section.evaluateHidden()
                    }
                    
                    if let section = self.form.sectionBy(tag: Sections.aboutNotificationTypes.tag) {
                        section.evaluateHidden()
                    }
                    
                    pinpad.dismiss(animated: true, completion: nil)
                    
                case .failure(let error):
                    self.dialogService.showRichError(error: error)
                }
            }
            
        // MARK: Users want to turn off the pin. Validate and turn off.
        case .turnOffPin?:
            guard accountService.validatePin(pin) else {
                pinpad.playWrongPinAnimation()
                pinpad.clearPin()
                break
            }
            
            accountService.dropSavedAccount()
            
            pinpad.dismiss(animated: true, completion: nil)
            
        // MARK: User wants to turn on biometry
        case .turnOnBiometry?:
            guard accountService.validatePin(pin) else {
                pinpad.playWrongPinAnimation()
                pinpad.clearPin()
                break
            }
            
            accountService.updateUseBiometry(true)
            pinpad.dismiss(animated: true, completion: nil)
            
        // MARK: User wants to turn off biometry
        case .turnOffBiometry?:
            guard accountService.validatePin(pin) else {
                pinpad.playWrongPinAnimation()
                pinpad.clearPin()
                break
            }
            
            accountService.updateUseBiometry(false)
            pinpad.dismiss(animated: true, completion: nil)
            
        default:
            pinpad.dismiss(animated: true, completion: nil)
        }

    }
    
    func didTapBiometryButton(viewController: UIViewController) {
    }
    
    func didTapCancel(viewController: UIViewController) {
    }
}

