//
//  LoginViewController+Pinpad.swift
//  Adamant
//
//  Created by Anokhov Pavel on 07.03.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import MyLittlePinpad
import CommonKit

extension LoginViewController {
    /// Shows pinpad in main.async queue
    func loginWithPinpad() {
        let button: PinpadBiometryButtonType = accountService.useBiometry ? localAuth.biometryType.pinpadButtonType : .hidden
        
        DispatchQueue.main.async { [weak self] in
            let pinpad = PinpadViewController.adamantPinpad(biometryButton: button)
            pinpad.commentLabel.text = String.adamant.login.loginIntoPrevAccount
            pinpad.commentLabel.isHidden = false
            pinpad.delegate = self
            pinpad.modalPresentationStyle = .overFullScreen
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
            self?.present(pinpad, animated: true, completion: nil)
        }
    }
    
    /// Request user biometry authentication
    func loginWithBiometry() {
        let biometry = localAuth.biometryType
        
        guard biometry == .touchID || biometry == .faceID else {
            return
        }
        
        Task { @MainActor in
            let result = await localAuth.authorizeUser(reason: .adamant.login.loginIntoPrevAccount)
            switch result {
            case .success:
                self.loginIntoSavedAccount()
                
            case .fallback:
                self.loginWithPinpad()
                
            case .cancel, .failed, .biometryLockout:
                break
            }
        }
    }
    
    @MainActor
    private func loginIntoSavedAccount() {
        dialogService.showProgress(withMessage: String.adamant.login.loggingInProgressMessage, userInteractionEnable: false)
        
        Task {
            do {
                let result = try await accountService.loginWithStoredAccount()
                handleSavedAccountLoginResult(result)
            } catch {
                dialogService.showRichError(error: error)
                
                if let pinpad = presentedViewController as? PinpadViewController {
                    pinpad.clearPin()
                }
            }
        }
    }
    
    private func handleSavedAccountLoginResult(_ result: AccountServiceResult) {
        switch result {
        case .success(_, let alert):
            dialogService.dismissProgress()
            
            let alertVc: UIAlertController?
            if let alert = alert {
                alertVc = UIAlertController(title: alert.title, message: alert.message, preferredStyleSafe: .alert, source: nil)
                alertVc!.addAction(UIAlertAction(title: String.adamant.alert.ok, style: .default))
            } else {
                alertVc = nil
            }
            
            guard let presenter = presentingViewController else {
                return
            }
            presenter.dismiss(animated: true, completion: nil)
            
            if let alertVc = alertVc {
                alertVc.modalPresentationStyle = .overFullScreen
                presenter.present(alertVc, animated: true, completion: nil)
            }
            
        case .failure(let error):
            dialogService.showRichError(error: error)
            
            if let pinpad = presentedViewController as? PinpadViewController {
                pinpad.clearPin()
            }
        }
    }
}

// MARK: - PinpadViewControllerDelegate
extension LoginViewController: PinpadViewControllerDelegate {
    nonisolated func pinpad(_ pinpad: PinpadViewController, didEnterPin pin: String) {
        Task { @MainActor in
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
    }
    
    nonisolated func pinpadDidTapBiometryButton(_ pinpad: PinpadViewController) {
        Task { @MainActor in
            let result = await localAuth.authorizeUser(reason: String.adamant.login.loginIntoPrevAccount)
            switch result {
            case .success:
                self.loginIntoSavedAccount()
                
            case .fallback, .cancel, .failed, .biometryLockout:
                break
            }
        }
    }
    
    nonisolated func pinpadDidCancel(_ pinpad: PinpadViewController) {
        Task { @MainActor in
            pinpad.dismiss(animated: true, completion: nil)
        }
    }
}
