//
//  TransferViewControllerBase+QR.swift
//  Adamant
//
//  Created by Anokhov Pavel on 29.08.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import QRCodeReader
import EFQRCode
import AVFoundation
import Photos

// MARK: - QR
extension TransferViewControllerBase {
    func scanQr() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            qrReader.modalPresentationStyle = .overFullScreen
            
            DispatchQueue.onMainAsync {
                self.present(self.qrReader, animated: true, completion: nil)
            }
            
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] (granted: Bool) in
                DispatchQueue.onMainAsync {
                    if granted, let qrReader = self?.qrReader {
                        qrReader.modalPresentationStyle = .overFullScreen
                        self?.present(qrReader, animated: true, completion: nil)
                    }
                }
            }
        case .restricted:
            let alert = UIAlertController(title: nil, message: String.adamantLocalized.login.cameraNotSupported, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: String.adamantLocalized.alert.ok, style: .cancel, handler: nil))
            alert.modalPresentationStyle = .overFullScreen

            DispatchQueue.onMainAsync {
                self.present(alert, animated: true, completion: nil)
            }
            
        case .denied:
            let alert = UIAlertController(title: nil, message: String.adamantLocalized.login.cameraNotAuthorized, preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: String.adamantLocalized.alert.settings, style: .default) { _ in
                DispatchQueue.main.async {
                    if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
                    }
                }
            })
            
            alert.addAction(UIAlertAction(title: String.adamantLocalized.alert.cancel, style: .cancel, handler: nil))
            alert.modalPresentationStyle = .overFullScreen
            
            DispatchQueue.onMainAsync {
                self.present(alert, animated: true, completion: nil)
            }
        @unknown default:
            break
        }
    }
    
    func loadQr() {
        let presenter: () -> Void = { [weak self] in
            let picker = UIImagePickerController()
            picker.delegate = self
            picker.allowsEditing = false
            picker.sourceType = .photoLibrary
            picker.modalPresentationStyle = .overFullScreen
            picker.overrideUserInterfaceStyle = .light
            self?.present(picker, animated: true, completion: nil)
        }
        
        presenter()
    }
}

// MARK: - ButtonsStripeViewDelegate
extension TransferViewControllerBase: ButtonsStripeViewDelegate {
    func buttonsStripe(_ stripe: ButtonsStripeView, didTapButton button: StripeButtonType) {
        switch button {
        case .qrCameraReader:
            scanQr()
            
        case .qrPhotoReader:
            loadQr()
            
        default:
            return
        }
    }
}

// MARK: - UIImagePickerControllerDelegate
extension TransferViewControllerBase: UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        dismiss(animated: true, completion: nil)
        
        guard let image = info[.originalImage] as? UIImage, let cgImage = image.cgImage else {
            return
        }
        
        let codes = EFQRCode.recognize(cgImage)
        if codes.count > 0 {
            for aCode in codes {
                if handleRawAddress(aCode) {
                    return
                }
            }
            
            dialogService.showWarning(withMessage: String.adamantLocalized.newChat.wrongQrError)
        } else {
            dialogService.showWarning(withMessage: String.adamantLocalized.login.noQrError)
        }
    }
}

// MARK: - QRCodeReaderViewControllerDelegate
extension TransferViewControllerBase: QRCodeReaderViewControllerDelegate {
    func reader(_ reader: QRCodeReaderViewController, didScanResult result: QRCodeReaderResult) {
        if handleRawAddress(result.value) {
            dismiss(animated: true, completion: nil)
        } else {
            dialogService.showWarning(withMessage: String.adamantLocalized.newChat.wrongQrError)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                reader.startScanning()
            }
        }
    }
    
    func readerDidCancel(_ reader: QRCodeReaderViewController) {
        reader.dismiss(animated: true, completion: nil)
    }
}
