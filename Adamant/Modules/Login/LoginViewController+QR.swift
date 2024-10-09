//
//  LoginViewController+QR.swift
//  Adamant
//
//  Created by Anokhov Pavel on 07.03.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import AVFoundation
import Photos
@preconcurrency import QRCodeReader
import EFQRCode
import CommonKit

extension LoginViewController {
    func loginWithQrFromCamera() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            let reader = QRCodeReaderViewController.adamantQrCodeReader()
            reader.delegate = self
            reader.modalPresentationStyle = .overFullScreen
            present(reader, animated: true, completion: nil)
            
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] (granted: Bool) in
                if granted {
                    DispatchQueue.onMainAsync {
                        let reader = QRCodeReaderViewController.adamantQrCodeReader()
                        reader.delegate = self
                        reader.modalPresentationStyle = .overFullScreen
                        self?.present(reader, animated: true, completion: nil)
                    }
                } else {
                    return
                }
            }
            
        case .restricted:
            let alert = UIAlertController(title: nil, message: String.adamant.login.cameraNotSupported, preferredStyleSafe: .alert, source: nil)
            alert.addAction(UIAlertAction(title: String.adamant.alert.ok, style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
            
        case .denied:
            dialogService.presentGoToSettingsAlert(title: nil, message: String.adamant.login.cameraNotAuthorized)
        @unknown default:
            break
        }
    }
    
    func loginWithQrFromLibrary() {
        let presenter: () -> Void = { [weak self] in
            let picker = UIImagePickerController()
            picker.delegate = self
            picker.allowsEditing = false
            picker.sourceType = .photoLibrary
            picker.modalPresentationStyle = .overFullScreen
            self?.present(picker, animated: true, completion: nil)
        }
        
        presenter()
    }
}

// MARK: - QRCodeReaderViewControllerDelegate
extension LoginViewController: QRCodeReaderViewControllerDelegate {
    nonisolated func reader(_ reader: QRCodeReaderViewController, didScanResult result: QRCodeReaderResult) {
        MainActor.assumeIsolated {
            guard AdamantUtilities.validateAdamantPassphrase(passphrase: result.value) else {
                dialogService.showWarning(withMessage: String.adamant.login.wrongQrError)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    reader.startScanning()
                }
                return
            }
            
            reader.dismiss(animated: true, completion: nil)
            loginWith(passphrase: result.value)
        }
    }
    
    nonisolated func readerDidCancel(_ reader: QRCodeReaderViewController) {
        MainActor.assumeIsolated {
            reader.dismiss(animated: true, completion: nil)
        }
    }
}

// MARK: - UIImagePickerControllerDelegate
extension LoginViewController: UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        guard !hidingImagePicker else { return }
        hidingImagePicker = true
        dismiss(animated: true) {
            self.hidingImagePicker = false
        }
        
        guard let image = info[.originalImage] as? UIImage, let cgImage = image.cgImage else {
            return
        }
        
        let codes = EFQRCode.recognize(cgImage)
        if codes.count > 0 {
            for aCode in codes {
                if AdamantUtilities.validateAdamantPassphrase(passphrase: aCode) {
                    loginWith(passphrase: aCode)
                    return
                }
            }
            
            dialogService.showWarning(withMessage: String.adamant.login.wrongQrError)
        } else {
            dialogService.showWarning(withMessage: String.adamant.login.noQrError)
        }
    }
}
