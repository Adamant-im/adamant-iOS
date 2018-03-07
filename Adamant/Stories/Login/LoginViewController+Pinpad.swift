//
//  LoginViewController+Pinpad.swift
//  Adamant
//
//  Created by Anokhov Pavel on 07.03.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import MyLittlePinpad

extension LoginViewController {
	/// Shows pinpad in main.async queue
	func loginWithPinpad() {
		let pinpad = PinpadViewController.adamantPinpad(biometryButton: localAuth.biometryType.pinpadButtonType)
		pinpad.commentLabel.text = String.adamantLocalized.login.loginIntoPrevAccount
		pinpad.commentLabel.isHidden = false
		pinpad.delegate = self
		
		DispatchQueue.main.async { [weak self] in
			self?.present(pinpad, animated: true, completion: nil)
		}
	}
	
	
	/// Request user biometry authentication
	func loginWithBiometry() {
		let biometry = localAuth.biometryType
		
		guard biometry == .touchID || biometry == .faceID else {
			return
		}
		
		localAuth.authorizeUser(reason: String.adamantLocalized.login.loginIntoPrevAccount, completion: { [weak self] result in
			switch result {
			case .success:
				self?.loginIntoSavedAccount()
				
			case .fallback:
				self?.loginWithPinpad()
				
			case .cancel:
				break
				
			case .failed:
				break
			}
		})
	}
	
	private func loginIntoSavedAccount() {
		guard accountService.hasSavedCredentials else {
			return
		}
	}
}


// MARK: - PinpadViewControllerDelegate
extension LoginViewController: PinpadViewControllerDelegate {
	func pinpad(_ pinpad: PinpadViewController, didEnterPin pin: String) {
		guard accountService.hasSavedCredentials, let savedPin = accountService.pin else {
			return
		}
		
		guard pin == savedPin else {
			pinpad.clearPin()
			pinpad.playWrongPinAnimation()
			return
		}
		
		loginIntoSavedAccount()
	}
	
	func pinpadDidTapBiometryButton(_ pinpad: PinpadViewController) {
		localAuth.authorizeUser(reason: String.adamantLocalized.login.loginIntoPrevAccount, completion: { [weak self] result in
			switch result {
			case .success:
				self?.loginIntoSavedAccount()
				
			case .fallback: break
			case .cancel: break
			case .failed: break
			}
		})
	}
	
	func pinpadDidCancel(_ pinpad: PinpadViewController) {
		pinpad.dismiss(animated: true, completion: nil)
	}
}
