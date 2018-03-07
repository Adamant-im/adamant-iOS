//
//  LoginViewController+QR.swift
//  Adamant
//
//  Created by Anokhov Pavel on 07.03.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import AVFoundation
import QRCodeReader

extension LoginViewController {
	func loginWithQr() {
		switch AVCaptureDevice.authorizationStatus(for: .video) {
		case .authorized:
			let reader = QRCodeReaderViewController.adamantQrCodeReader()
			reader.delegate = self
			present(reader, animated: true, completion: nil)
			
		case .notDetermined:
			AVCaptureDevice.requestAccess(for: .video) { [weak self] (granted: Bool) in
				if granted {
					if Thread.isMainThread {
						let reader = QRCodeReaderViewController.adamantQrCodeReader()
						reader.delegate = self
						self?.present(reader, animated: true, completion: nil)
					} else {
						DispatchQueue.main.async {
							let reader = QRCodeReaderViewController.adamantQrCodeReader()
							reader.delegate = self
							self?.present(reader, animated: true, completion: nil)
						}
					}
				} else {
					return
				}
			}
			
		case .restricted:
			let alert = UIAlertController(title: nil, message: String.adamantLocalized.login.cameraNotSupported, preferredStyle: .alert)
			alert.addAction(UIAlertAction(title: String.adamantLocalized.alert.ok, style: .cancel, handler: nil))
			present(alert, animated: true, completion: nil)
			
		case .denied:
			let alert = UIAlertController(title: nil, message: String.adamantLocalized.login.cameraNotAuthorized, preferredStyle: .alert)
			
			alert.addAction(UIAlertAction(title: String.adamantLocalized.alert.settings, style: .default) { _ in
				DispatchQueue.main.async {
					if let settingsURL = URL(string: UIApplicationOpenSettingsURLString) {
						UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
					}
				}
			})
			
			alert.addAction(UIAlertAction(title: String.adamantLocalized.alert.cancel, style: .cancel, handler: nil))
			
			present(alert, animated: true, completion: nil)
		}
	}
}


// MARK: - QRCodeReaderViewControllerDelegate
extension LoginViewController: QRCodeReaderViewControllerDelegate {
	func reader(_ reader: QRCodeReaderViewController, didScanResult result: QRCodeReaderResult) {
		guard AdamantUtilities.validateAdamantPassphrase(passphrase: result.value) else {
			dialogService.showError(withMessage: String.adamantLocalized.login.wrongQrError)
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
				reader.startScanning()
			}
			return
		}
		
		reader.dismiss(animated: true, completion: nil)
		loginWith(passphrase: result.value)
	}
	
	func readerDidCancel(_ reader: QRCodeReaderViewController) {
		reader.dismiss(animated: true, completion: nil)
	}
}
