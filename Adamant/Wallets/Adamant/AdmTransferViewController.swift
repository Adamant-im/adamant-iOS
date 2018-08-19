//
//  AdmTransferViewController.swift
//  Adamant
//
//  Created by Anokhov Pavel on 18.08.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import Eureka
import QRCodeReader
import EFQRCode
import AVFoundation
import Photos

class AdmTransferViewController: TransferViewControllerBase {
	// MARK: Properties
	override var balanceFormatter: NumberFormatter {
		return AdamantUtilities.currencyFormatter
	}
	
	private var skipValueChange: Bool = false
	
	lazy var qrReader: QRCodeReaderViewController = {
		let builder = QRCodeReaderViewControllerBuilder {
			$0.reader = QRCodeReader(metadataObjectTypes: [.qr ], captureDevicePosition: .back)
			$0.cancelButtonTitle = String.adamantLocalized.alert.cancel
			$0.showSwitchCameraButton = false
		}
		
		let vc = QRCodeReaderViewController(builder: builder)
		vc.delegate = self
		return vc
	}()
	
	
	// MARK: Overrides
	private var _recipient: String?
	
	override var recipient: String? {
		set {
			if let recipient = newValue, let first = recipient.first, first != "U" {
				_recipient = "U\(recipient)"
			} else {
				_recipient = newValue
			}
		}
		get {
			return _recipient
		}
	}
	
	override func customSections() -> [Section] {
		// MARK: - Recipient section
		
		let recipientSection = Section(Sections.recipient.localized) {
			$0.tag = Sections.recipient.tag
			
			$0.footer = { [weak self] in
				var footer = HeaderFooterView<UIView>(.callback {
					let view = ButtonsStripeView.adamantConfigured()
					view.stripe = [.qrCameraReader, .qrPhotoReader]
					view.delegate = self
					return view
					})
				
				footer.height = { ButtonsStripeView.adamantDefaultHeight }
				
				return footer
			}()
		}
		
		// MARK: address field
		<<< TextRow() {
			$0.tag = BaseRows.address.tag
			$0.cell.textField.placeholder = String.adamantLocalized.newChat.addressPlaceholder
			$0.cell.textField.keyboardType = .numberPad
			
			let prefix = UILabel()
			prefix.text = "U"
			prefix.sizeToFit()
			let view = UIView()
			view.addSubview(prefix)
			view.frame = prefix.frame
			$0.cell.textField.leftView = view
			$0.cell.textField.leftViewMode = .always
		}.cellUpdate { (cell, row) in
			if let text = cell.textField.text {
				cell.textField.text = text.components(separatedBy: NewChatViewController.invalidCharacters).joined()
			}
		}.onChange { [weak self] row in
			if let skip = self?.skipValueChange, skip {
				self?.skipValueChange = false
				return
			}
			
			if let text = row.value {
				let trimmed = text.components(separatedBy: NewChatViewController.invalidCharacters).joined()
				
				if text != trimmed {
					self?.skipValueChange = true
					
					DispatchQueue.main.async {
						row.value = trimmed
						row.updateCell()
					}
				}
			}
			
			self?.validateForm()
		}
		
		
		// MARK: - Info section
		let infoSection = Section(Sections.transferInfo.localized) {
			$0.tag = Sections.transferInfo.tag
		}
		
		// MARK: Amount
		<<< DecimalRow { [weak self] in
			$0.title = BaseRows.amount.localized
			$0.placeholder = String.adamantLocalized.transfer.amountPlaceholder
			$0.tag = BaseRows.amount.tag
			$0.formatter = self?.balanceFormatter
			
			if let amount = self?.amount {
				$0.value = amount.doubleValue
			}
		}.onChange { [weak self] (row) in
			self?.validateForm()
		}
		
		// MARK: Fee
		<<< DecimalRow() { [weak self] in
			$0.tag = BaseRows.fee.tag
			$0.title = BaseRows.fee.localized
			$0.disabled = true
			$0.formatter = self?.balanceFormatter
			
			if let fee = self?.service?.transactionFee {
				$0.value = fee.doubleValue
			} else {
				$0.value = 0
			}
		}
		
		// MARK: Total
		<<< DecimalRow() { [weak self] in
			$0.tag = BaseRows.total.tag
			$0.title = BaseRows.total.localized
			$0.value = nil
			$0.disabled = true
			$0.formatter = self?.balanceFormatter
			
			if let balance = self?.service?.wallet?.balance {
				$0.add(rule: RuleSmallerOrEqualThan<Double>(max: balance.doubleValue))
			}
		}
		
		return [recipientSection, infoSection]
	}
	
	override func validateRecipient(_ address: String) -> Bool {
		let fixedAddress: String
		if let first = address.first, first != "U" {
			fixedAddress = "U\(address)"
		} else {
			fixedAddress = address
		}
		
		switch AdamantUtilities.validateAdamantAddress(address: fixedAddress) {
		case .valid:
			return true
			
		case .system, .invalid:
			return false
		}
	}
	
	override func sendFunds() {
		guard let service = service, let recipient = recipient, let amount = amount else {
			return
		}
		
		guard let dialogService = dialogService else {
			return
		}
		
		dialogService.showProgress(withMessage: String.adamantLocalized.transfer.transferProcessingMessage, userInteractionEnable: false)
		
		service.sendMoney(recipient: recipient, amount: amount) { [weak self] result in
			switch result {
			case .success:
				dialogService.showSuccess(withMessage: String.adamantLocalized.transfer.transferSuccess)
				
				if let vc = self, let delegate = vc.delegate {
					delegate.transferViewController(vc, didFinishWith: nil)
				}
				
				service.update()
				
			case .failure(let error):
				dialogService.dismissProgress()
				dialogService.showRichError(error: error)
			}
		}
	}
	
	
	// MARK: Tools
	private func handleUri(_ uri: AdamantUri) -> Bool {
		switch uri {
		case .address(let address, _):
			if let row: TextRow = form.rowBy(tag: BaseRows.address.tag) {
				row.value = address
				row.updateCell()
			}
			
			return true
			
		default:
			return false
		}
	}
}


// MARK: - ButtonsStripeViewDelegate
extension AdmTransferViewController: ButtonsStripeViewDelegate {
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


// MARK: - QR
extension AdmTransferViewController {
	func scanQr() {
		switch AVCaptureDevice.authorizationStatus(for: .video) {
		case .authorized:
			present(qrReader, animated: true, completion: nil)
			
		case .notDetermined:
			AVCaptureDevice.requestAccess(for: .video) { [weak self] (granted: Bool) in
				if granted, let qrReader = self?.qrReader {
					if Thread.isMainThread {
						self?.present(qrReader, animated: true, completion: nil)
					} else {
						DispatchQueue.main.async {
							self?.present(qrReader, animated: true, completion: nil)
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
	
	func loadQr() {
		let presenter: () -> Void = { [weak self] in
			let picker = UIImagePickerController()
			picker.delegate = self
			picker.allowsEditing = false
			picker.sourceType = .photoLibrary
			self?.present(picker, animated: true, completion: nil)
		}
		
		if #available(iOS 11.0, *) {
			presenter()
		} else {
			switch PHPhotoLibrary.authorizationStatus() {
			case .authorized:
				presenter()
				
			case .notDetermined:
				PHPhotoLibrary.requestAuthorization { status in
					if status == .authorized {
						presenter()
					}
				}
				
			case .restricted, .denied:
				dialogService.presentGoToSettingsAlert(title: nil, message: String.adamantLocalized.login.photolibraryNotAuthorized)
			}
		}
	}
}


// MARK: - UIImagePickerControllerDelegate
extension AdmTransferViewController: UINavigationControllerDelegate, UIImagePickerControllerDelegate {
	func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
		dismiss(animated: true, completion: nil)
		
		guard let image = info[UIImagePickerControllerOriginalImage] as? UIImage else {
			return
		}
		
		if let cgImage = image.toCGImage(), let codes = EFQRCode.recognize(image: cgImage), codes.count > 0 {
			for aCode in codes {
				if let uri = AdamantUriTools.decode(uri: aCode), handleUri(uri) {
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
extension AdmTransferViewController: QRCodeReaderViewControllerDelegate {
	func reader(_ reader: QRCodeReaderViewController, didScanResult result: QRCodeReaderResult) {
		guard let uri = AdamantUriTools.decode(uri: result.value) else {
			dialogService.showWarning(withMessage: String.adamantLocalized.newChat.wrongQrError)
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
				reader.startScanning()
			}
			return
		}
		
		if handleUri(uri) {
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
