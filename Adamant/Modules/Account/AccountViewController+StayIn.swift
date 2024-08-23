//
//  AccountViewController+StayIn.swift
//  Adamant
//
//  Created by Anokhov Pavel on 10.11.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import Eureka
import MyLittlePinpad
import CommonKit

extension AccountViewController {
    func setStayLoggedIn(enabled: Bool) {
        guard accountService.hasStayInAccount != enabled else {
            return
        }
        
        if enabled { // Create pin and turn on Stay In
            pinpadRequest = .createPin
            let pinpad = PinpadViewController.adamantPinpad(biometryButton: .hidden)
            pinpad.commentLabel.text = String.adamant.pinpad.createPin
            pinpad.commentLabel.isHidden = false
            pinpad.delegate = self
            pinpad.modalPresentationStyle = .overFullScreen
            pinpad.backgroundView.backgroundColor = UIColor.adamant.backgroundColor
            setColors(for: pinpad)
            present(pinpad, animated: true, completion: nil)
        } else { // Validate pin and turn off Stay In
            pinpadRequest = .turnOffPin
            let biometryButton: PinpadBiometryButtonType = accountService.useBiometry ? localAuth.biometryType.pinpadButtonType : .hidden
            let pinpad = PinpadViewController.adamantPinpad(biometryButton: biometryButton)
            pinpad.commentLabel.text = String.adamant.security.stayInTurnOff
            pinpad.commentLabel.isHidden = false
            pinpad.delegate = self
            pinpad.modalPresentationStyle = .overFullScreen
            setColors(for: pinpad)
            present(pinpad, animated: true, completion: nil)
        }
    }
    
    // MARK: Use biometry
    func setBiometry(enabled: Bool) {
        guard showLoggedInOptions, accountService.hasStayInAccount, accountService.useBiometry != enabled else {
            return
        }
        
        let reason = enabled ? String.adamant.security.biometryOnReason : String.adamant.security.biometryOffReason
        localAuth.authorizeUser(reason: reason) { result in
            Task { @MainActor [weak self] in
                switch result {
                case .success:
                    self?.dialogService.showSuccess(withMessage: String.adamant.alert.done)
                    self?.accountService.updateUseBiometry(enabled)
                    
                case .cancel:
                    if let row: SwitchRow = self?.form.rowBy(tag: Rows.biometry.tag) {
                        row.value = self?.accountService.useBiometry
                        row.updateCell()
                    }
                    
                case .fallback:
                    let pinpad = PinpadViewController.adamantPinpad(biometryButton: .hidden)
                    
                    if enabled {
                        pinpad.commentLabel.text = String.adamant.security.biometryOnReason
                        self?.pinpadRequest = .turnOnBiometry
                    } else {
                        pinpad.commentLabel.text = String.adamant.security.biometryOffReason
                        self?.pinpadRequest = .turnOffBiometry
                    }
                    
                    pinpad.commentLabel.isHidden = false
                    pinpad.delegate = self
                    pinpad.modalPresentationStyle = .overFullScreen
                    self?.setColors(for: pinpad)
                    self?.present(pinpad, animated: true, completion: nil)
                    
                case .failed:
                    if let row: SwitchRow = self?.form.rowBy(tag: Rows.biometry.tag) {
                        if let value = self?.accountService.useBiometry {
                            row.value = value
                        } else {
                            row.value = false
                        }
                        
                        row.updateCell()
                        row.evaluateHidden()
                    }
                    
                    if let row = self?.form.rowBy(tag: Rows.notifications.tag) {
                        row.evaluateHidden()
                    }
                }
            }
        }
    }
    
    func setColors(for pinpad: PinpadViewController) {
        pinpad.backgroundView.backgroundColor = UIColor.adamant.backgroundColor
        pinpad.buttonsBackgroundColor = UIColor.adamant.backgroundColor
        pinpad.view.subviews.forEach { view in
            view.subviews.forEach { _view in
                if _view.backgroundColor == .white {
                    _view.backgroundColor = UIColor.adamant.backgroundColor
                }
            }
        }
        pinpad.commentLabel.backgroundColor = UIColor.adamant.backgroundColor
    }
}

// MARK: - PinpadViewControllerDelegate
extension AccountViewController: PinpadViewControllerDelegate {
    func pinpad(_ pinpad: PinpadViewController, didEnterPin pin: String) {
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
            
            accountService.setStayLoggedIn(pin: pin) { [weak self] result in
                switch result {
                case .success:
                    self?.pinpadRequest = nil
                    DispatchQueue.main.async {
                        if let row: SwitchRow = self?.form.rowBy(tag: Rows.biometry.tag) {
                            row.value = false
                            row.updateCell()
                            row.evaluateHidden()
                        }
                        
                        if let row = self?.form.rowBy(tag: Rows.notifications.tag) {
                            row.evaluateHidden()
                        }
                        
                        pinpad.dismiss(animated: true, completion: nil)
                    }
                    
                case .failure(let error):
                    self?.dialogService.showRichError(error: error)
                }
            }
            
        // MARK: Users want to turn off the pin. Validate and turn off.
        case .turnOffPin?:
            guard accountService.validatePin(pin, isInitialLoginAttempt: false) else {
                pinpad.playWrongPinAnimation()
                pinpad.clearPin()
                break
            }
            
            accountService.dropSavedAccount()
            
            pinpad.dismiss(animated: true, completion: nil)
            
        // MARK: User wants to turn on biometry
        case .turnOnBiometry?:
            guard accountService.validatePin(pin, isInitialLoginAttempt: false) else {
                pinpad.playWrongPinAnimation()
                pinpad.clearPin()
                break
            }
            
            accountService.updateUseBiometry(true)
            pinpad.dismiss(animated: true, completion: nil)
            
        // MARK: User wants to turn off biometry
        case .turnOffBiometry?:
            guard accountService.validatePin(pin, isInitialLoginAttempt: false) else {
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
    
    func pinpadDidTapBiometryButton(_ pinpad: PinpadViewController) {
        switch pinpadRequest {
            
        // MARK: User wants to turn of StayIn with his face. Or finger.
        case .turnOffPin?:
            localAuth.authorizeUser(reason: String.adamant.security.stayInTurnOff, completion: { [weak self] result in
                switch result {
                case .success:
                    self?.accountService.dropSavedAccount()
                    
                    DispatchQueue.main.async {
                        if let row: SwitchRow = self?.form.rowBy(tag: Rows.biometry.tag) {
                            row.value = false
                            row.updateCell()
                            row.evaluateHidden()
                        }
                        
                        if let row = self?.form.rowBy(tag: Rows.notifications.tag) {
                            row.evaluateHidden()
                        }
                        
                        pinpad.dismiss(animated: true, completion: nil)
                    }
                    
                case .cancel: break
                case .fallback: break
                case .failed: break
                }
            })
            
        default:
            return
        }
    }
    
    func pinpadDidCancel(_ pinpad: PinpadViewController) {
        switch pinpadRequest {
            
        // MARK: User canceled turning on StayIn
        case .createPin?, .reenterPin(pin: _)?:
            if let row: SwitchRow = form.rowBy(tag: Rows.stayIn.tag) {
                row.value = false
                row.updateCell()
            }
            
        // MARK: User canceled turning off StayIn
        case .turnOffPin?:
            if let row: SwitchRow = form.rowBy(tag: Rows.stayIn.tag) {
                row.value = true
                row.updateCell()
            }
            
        // MARK: User canceled Biometry On
        case .turnOnBiometry?:
            if let row: SwitchRow = form.rowBy(tag: Rows.biometry.tag) {
                row.value = false
                row.updateCell()
            }
            
        // MARK: User canceled Biometry Off
        case .turnOffBiometry?:
            if let row: SwitchRow = form.rowBy(tag: Rows.biometry.tag) {
                row.value = true
                row.updateCell()
            }
            
        default:
            break
        }
        
        pinpadRequest = nil
        pinpad.dismiss(animated: true, completion: nil)
    }
}
