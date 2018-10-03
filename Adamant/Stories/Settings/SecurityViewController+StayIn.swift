//
//  SecurityViewController+StayIn.swift
//  Adamant
//
//  Created by Anokhov Pavel on 04.07.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import Eureka
import MyLittlePinpad

extension SecurityViewController {
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
			pinpadRequest = .turnOffPin
			let biometryButton: PinpadBiometryButtonType = accountService.useBiometry ? localAuth.biometryType.pinpadButtonType : .hidden
			let pinpad = PinpadViewController.adamantPinpad(biometryButton: biometryButton)
			pinpad.commentLabel.text = String.adamantLocalized.security.stayInTurnOff
			pinpad.commentLabel.isHidden = false
			pinpad.delegate = self
			
			present(pinpad, animated: true, completion: nil)
		}
	}
	
	// MARK: Use biometry
	func setBiometry(enabled: Bool) {
		guard showLoggedInOptions, accountService.hasStayInAccount, accountService.useBiometry != enabled else {
			return
		}
		
		let reason = enabled ? String.adamantLocalized.security.biometryOnReason : String.adamantLocalized.security.biometryOffReason
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
					pinpad.commentLabel.text = String.adamantLocalized.security.biometryOnReason
					self?.pinpadRequest = .turnOnBiometry
				} else {
					pinpad.commentLabel.text = String.adamantLocalized.security.biometryOffReason
					self?.pinpadRequest = .turnOffBiometry
				}
				
				pinpad.commentLabel.isHidden = false
				pinpad.delegate = self
				
				DispatchQueue.main.async {
					self?.present(pinpad, animated: true, completion: nil)
				}
				
			case .failed:
				DispatchQueue.main.async {
					if let row: SwitchRow = self?.form.rowBy(tag: Rows.biometry.tag) {
						if let value = self?.accountService.useBiometry {
							row.value = value
						} else {
							row.value = false
						}
						
						row.updateCell()
						row.evaluateHidden()
					}
					
					if let section = self?.form.sectionBy(tag: Sections.notifications.tag) {
						section.evaluateHidden()
					}
				}
			}
		}
	}
}


// MARK: - PinpadViewControllerDelegate
extension SecurityViewController: PinpadViewControllerDelegate {
	func pinpad(_ pinpad: PinpadViewController, didEnterPin pin: String) {
		switch pinpadRequest {
			
		// MARK: User has entered new pin first time. Request re-enter pin
		case .createPin?:
			pinpadRequest = .reenterPin(pin: pin)
			pinpad.commentLabel.text = String.adamantLocalized.pinpad.reenterPin
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
						
						if let section = self?.form.sectionBy(tag: Sections.notifications.tag) {
							section.evaluateHidden()
						}
						
						if let section = self?.form.sectionBy(tag: Sections.aboutNotificationTypes.tag) {
							section.evaluateHidden()
						}
						
						pinpad.dismiss(animated: true, completion: nil)
					}
					
				case .failure(let error):
					self?.dialogService.showRichError(error: error)
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
			
			accountService.useBiometry = true
			pinpad.dismiss(animated: true, completion: nil)
			
			
		// MARK: User wants to turn off biometry
		case .turnOffBiometry?:
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
		case .turnOffPin?:
			localAuth.authorizeUser(reason: String.adamantLocalized.security.stayInTurnOff, completion: { [weak self] result in
				switch result {
				case .success:
					self?.accountService.dropSavedAccount()
					
					DispatchQueue.main.async {
						if let row: SwitchRow = self?.form.rowBy(tag: Rows.biometry.tag) {
							row.value = false
							row.updateCell()
							row.evaluateHidden()
						}
						
						if let section = self?.form.sectionBy(tag: Sections.notifications.tag) {
							section.evaluateHidden()
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
