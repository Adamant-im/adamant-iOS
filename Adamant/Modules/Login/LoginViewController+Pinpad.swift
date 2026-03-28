//
//  LoginViewController+Pinpad.swift
//  Adamant
//
//  Created by Anokhov Pavel on 07.03.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import CommonKit
import Foundation
import MyLittlePinpad

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

        localAuth.authorizeUser(reason: .adamant.login.loginIntoPrevAccount) { result in
            Task { @MainActor [weak self] in
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
            }
        }
    }

    @MainActor
    private func loginIntoSavedAccount() {
        dialogService.showProgress(withMessage: String.adamant.login.loggingInProgressMessage, userInteractionEnable: false)

        Task {
            do {
                try await accountService.loginWithStoredAccount()
                dialogService.dismissProgress()

                guard let presenter = presentingViewController else {
                    return
                }

                presenter.dismiss(animated: true, completion: nil)

                presentUpdateV12AlertIfNeeded(presenter: presenter)
            } catch {
                dialogService.showRichError(error: error)

                if let pinpad = presentedViewController as? PinpadViewController {
                    pinpad.clearPin()
                }
            }
        }
    }

    private func presentUpdateV12AlertIfNeeded(presenter: UIViewController) {
        let alertVc = UIAlertController(
            title: String.adamant.accountService.updateAlertTitleV12,
            message: String.adamant.accountService.updateAlertMessageV12,
            preferredStyleSafe: .alert,
            source: nil
        )
        alertVc.addAction(UIAlertAction(title: String.adamant.alert.ok, style: .default))
        alertVc.modalPresentationStyle = .overFullScreen
        presenter.present(alertVc, animated: true, completion: nil)
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
            localAuth.authorizeUser(
                reason: String.adamant.login.loginIntoPrevAccount,
                completion: { [weak self] result in
                    switch result {
                    case .success:
                        self?.loginIntoSavedAccount()

                    case .fallback, .cancel, .failed:
                        break
                    }
                }
            )
        }
    }

    nonisolated func pinpadDidCancel(_ pinpad: PinpadViewController) {
        Task { @MainActor in
            pinpad.dismiss(animated: true, completion: nil)
        }
    }
}
