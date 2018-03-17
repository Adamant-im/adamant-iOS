//
//  SettingsViewController+Pinpad.swift
//  Adamant
//
//  Created by Anokhov Pavel on 09.03.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import Eureka
import MyLittlePinpad

// MARK: - Properties
extension SettingsViewController {
	enum PinpadRequest {
		case createPin
		case reenterPin(pin: String)
		case turnOffPin
		case turnOnBiometry
		case turnOffBiometry
	}
	
	// MARK: Stay in
	func setStayLoggedIn(enabled: Bool) {
		guard accountService.hasStayInAccount != enabled else {
			return
		}
		
		if enabled { // Create pin and turn on Stay In
			pinpadRequest = .createPin
			let pinpad = PinpadViewController.adamantPinpad(biometryButton: .hidden)
			pinpad.commentLabel.text = String.adamantLocalized.pinpad.createPin
			pinpad.commentLabel.isHidden = false
			pinpad.delegate = self
			present(pinpad, animated: true, completion: nil)
		} else { // Validate pin and turn off Stay In
			pinpadRequest = PinpadRequest.turnOffPin
			let biometryButton: PinpadBiometryButtonType = accountService.useBiometry ? localAuth.biometryType.pinpadButtonType : .hidden
			let pinpad = PinpadViewController.adamantPinpad(biometryButton: biometryButton)
			pinpad.commentLabel.text = String.adamantLocalized.settings.stayInTurnOff
			pinpad.commentLabel.isHidden = false
			pinpad.delegate = self
			
			present(pinpad, animated: true, completion: nil)
		}
	}
	
	// MARK: Use biometry
	func setBiometry(enabled: Bool) {
		guard showBiometryRow, accountService.hasStayInAccount, accountService.useBiometry != enabled else {
			return
		}
		
		let reason = enabled ? String.adamantLocalized.settings.biometryOnReason : String.adamantLocalized.settings.biometryOffReason
		localAuth.authorizeUser(reason: reason) { [weak self] result in
			switch result {
			case .success:
				self?.dialogService.showSuccess(withMessage: String.adamantLocalized.alert.done)
				self?.accountService.useBiometry = enabled
				
			case .cancel:
				DispatchQueue.main.async { [weak self] in
					if let row: SwitchRow = self?.form.rowBy(tag: Rows.biometry.tag) {
						row.value = self?.accountService.useBiometry
						row.updateCell()
					}
				}
				
			case .fallback:
				let pinpad = PinpadViewController.adamantPinpad(biometryButton: .hidden)
				
				if enabled {
					pinpad.commentLabel.text = String.adamantLocalized.settings.biometryOnReason
					self?.pinpadRequest = PinpadRequest.turnOnBiometry
				} else {
					pinpad.commentLabel.text = String.adamantLocalized.settings.biometryOffReason
					self?.pinpadRequest = PinpadRequest.turnOffBiometry
				}
				
				pinpad.commentLabel.isHidden = false
				pinpad.delegate = self
				
				DispatchQueue.main.async {
					self?.present(pinpad, animated: true, completion: nil)
				}
				
			case .failed:
				DispatchQueue.main.async {
					guard let row: SwitchRow = self?.form.rowBy(tag: Rows.biometry.tag) else {
						return
					}
					
					if let value = self?.accountService.useBiometry {
						row.value = value
					} else {
						row.value = false
					}
					
					row.updateCell()
					row.evaluateHidden()
				}
			}
		}
	}
}


// MARK: - PinpadViewControllerDelegate
extension SettingsViewController: PinpadViewControllerDelegate {
	func pinpad(_ pinpad: PinpadViewController, didEnterPin pin: String) {
		switch pinpadRequest {
			
		// MARK: User has entered new pin first time. Request re-enter pin
		case PinpadRequest.createPin?:
			pinpadRequest = PinpadRequest.reenterPin(pin: pin)
			pinpad.commentLabel.text = String.adamantLocalized.pinpad.reenterPin
			pinpad.clearPin()
			return
			
			
		// MARK: User has reentered pin. Save pin.
		case PinpadRequest.reenterPin(let pinToVerify)?:
			guard pin == pinToVerify else {
				pinpad.playWrongPinAnimation()
				pinpad.clearPin()
				break
			}
			
			accountService.setStayLoggedIn(pin: pin) { [weak self] result in
				switch result {
				case .success(account: _):
					self?.pinpadRequest = nil
					DispatchQueue.main.async {
						if let biometryType = self?.localAuth.biometryType,
							biometryType == .touchID || biometryType == .faceID,
							let row: SwitchRow = self?.form.rowBy(tag: Rows.biometry.tag) {
							self?.showBiometryRow = true
							row.value = false
							row.updateCell()
							row.evaluateHidden()
						}
						
						pinpad.dismiss(animated: true, completion: nil)
					}
					
				case .failure(let error):
					self?.dialogService.showError(withMessage: error.localized)
				}
			}
			
			
		// MARK: Users want to turn off the pin. Validate and turn off.
		case PinpadRequest.turnOffPin?:
			guard accountService.validatePin(pin) else {
				pinpad.playWrongPinAnimation()
				pinpad.clearPin()
				break
			}
			
			accountService.dropSavedAccount()
			if let row: SwitchRow = form.rowBy(tag: Rows.biometry.tag) {
				showBiometryRow = false
				row.value = false
				row.updateCell()
				row.evaluateHidden()
			}
			
			pinpad.dismiss(animated: true, completion: nil)
			
			
		// MARK: User wants to turn on biometry
		case PinpadRequest.turnOnBiometry?:
			guard accountService.validatePin(pin) else {
				pinpad.playWrongPinAnimation()
				pinpad.clearPin()
				break
			}
			
			accountService.useBiometry = true
			pinpad.dismiss(animated: true, completion: nil)
			
			
		// MARK: User wants to turn off biometry
		case PinpadRequest.turnOffBiometry?:
			guard accountService.validatePin(pin) else {
				pinpad.playWrongPinAnimation()
				pinpad.clearPin()
				break
			}
			
			accountService.useBiometry = false
			pinpad.dismiss(animated: true, completion: nil)
			
		default:
			pinpad.dismiss(animated: true, completion: nil)
		}
	}
	
	func pinpadDidTapBiometryButton(_ pinpad: PinpadViewController) {
		switch pinpadRequest {
			
		// MARK: User wants to turn of StayIn with his face. Or finger.
		case PinpadRequest.turnOffPin?:
			localAuth.authorizeUser(reason: String.adamantLocalized.settings.stayInTurnOff, completion: { [weak self] result in
				switch result {
				case .success:
					self?.accountService.dropSavedAccount()
					
					DispatchQueue.main.async {
						if let row: SwitchRow = self?.form.rowBy(tag: Rows.biometry.tag) {
							self?.showBiometryRow = false
							row.value = false
							row.updateCell()
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
		case PinpadRequest.createPin?,
			 PinpadRequest.reenterPin(pin: _)?:
			if let row: SwitchRow = form.rowBy(tag: Rows.stayLoggedIn.tag) {
				row.value = false
				row.updateCell()
			}
			
		// MARK: User canceled turning off StayIn
		case PinpadRequest.turnOffPin?:
			if let row: SwitchRow = form.rowBy(tag: Rows.stayLoggedIn.tag) {
				row.value = true
				row.updateCell()
			}
			
		// MARK: User canceled Biometry On
		case PinpadRequest.turnOnBiometry?:
			if let row: SwitchRow = form.rowBy(tag: Rows.biometry.tag) {
				row.value = false
				row.updateCell()
			}
			
		// MARK: User canceled Biometry Off
		case PinpadRequest.turnOffBiometry?:
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
