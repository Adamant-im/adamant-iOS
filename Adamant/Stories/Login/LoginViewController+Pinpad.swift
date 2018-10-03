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
		let button: PinpadBiometryButtonType = accountService.useBiometry ? localAuth.biometryType.pinpadButtonType : .hidden
		
		DispatchQueue.main.async { [weak self] in
			let pinpad = PinpadViewController.adamantPinpad(biometryButton: button)
			pinpad.commentLabel.text = String.adamantLocalized.login.loginIntoPrevAccount
			pinpad.commentLabel.isHidden = false
			pinpad.delegate = self
			
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
		dialogService.showProgress(withMessage: String.adamantLocalized.login.loggingInProgressMessage, userInteractionEnable: false)
		
		accountService.loginWithStoredAccount { [weak self] result in
			switch result {
			case .success(_, let alert):
				self?.dialogService.dismissProgress()
				
				guard let presenter = self?.presentingViewController else {
					return
				}
				
				let alertVc: UIAlertController?
				if let alert = alert {
					alertVc = UIAlertController(title: alert.title, message: alert.message, preferredStyle: .alert)
					alertVc!.addAction(UIAlertAction(title: String.adamantLocalized.alert.ok, style: .default))
				} else {
					alertVc = nil
				}
				
				if Thread.isMainThread {
					presenter.dismiss(animated: true, completion: nil)
					
					if let alertVc = alertVc {
						presenter.present(alertVc, animated: true, completion: nil)
					}
				} else {
					DispatchQueue.main.async {
						presenter.dismiss(animated: true, completion: nil)
						
						if let alertVc = alertVc {
							presenter.present(alertVc, animated: true, completion: nil)
						}
					}
				}
				
			case .failure(let error):
				self?.dialogService.showRichError(error: error)
				
				if let pinpad = self?.presentedViewController as? PinpadViewController {
					pinpad.clearPin()
				}
			}
		}
	}
}


// MARK: - PinpadViewControllerDelegate
extension LoginViewController: PinpadViewControllerDelegate {
	func pinpad(_ pinpad: PinpadViewController, didEnterPin pin: String) {
		guard accountService.hasStayInAccount else {
			return
		}
		
		guard accountService.validatePin(pin) else {
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
				
			case .fallback, .cancel, .failed:
				break
			}
		})
	}
	
	func pinpadDidCancel(_ pinpad: PinpadViewController) {
		pinpad.dismiss(animated: true, completion: nil)
	}
}
