//
//  NewChatViewController.swift
//  Adamant
//
//  Created by Anokhov Pavel on 21.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import Eureka
import QRCodeReader
import EFQRCode
import AVFoundation
import Photos

// MARK: - Localization
extension String.adamantLocalized {
	struct newChat {
		static let title = NSLocalizedString("NewChatScene.Title", comment: "New chat: scene title")
		
		static let addressPlaceholder = NSLocalizedString("NewChatScene.Address.Placeholder", comment: "New chat: Recipient address placeholder. Note that address text field always shows U letter, so you can left this line blank.")
		static let scanQrButton = NSLocalizedString("NewChatScene.ScanQr", comment: "New chat: Scan QR with address button")
		
		static let specifyValidAddressMessage = NSLocalizedString("NewChatScene.Error.InvalidAddress", comment: "New chat: Notify user that he did enter invalid address")
		static let loggedUserAddressMessage = NSLocalizedString("NewChatScene.Error.OwnAddress", comment: "New chat: Notify user that he can't start chat with himself")
		
		static let wrongQrError = NSLocalizedString("NewChatScene.Error.WrongQr", comment: "New Chat: Notify user that scanned QR doesn't contains an address")
		static let addressNotFoundFormat = NSLocalizedString("NewChatScene.Error.AddressNotFoundFormat", comment: "New chat: Notify user that specified address (%@) not found. Using %@ for address")
		static let serverErrorFormat = NSLocalizedString("NewChatScene.Error.RemoteServerFormat", comment: "New chat: Remote server returned an error. Using %@ for error description")
		
		private init() { }
	}
}


// MARK: - Delegate
protocol NewChatViewControllerDelegate: class {
	func newChatController(_ controller: NewChatViewController, didSelectAccount account: CoreDataAccount)
}


// MARK: -
class NewChatViewController: FormViewController {
	private enum Rows {
		case addressField
		case scanQr
		
		var tag: String {
			switch self {
			case .addressField:
				return "a"
				
			case .scanQr:
				return "b"
			}
		}
	}
	
	// MARK: Dependencies
	var dialogService: DialogService!
	var accountService: AccountService!
	var accountsProvider: AccountsProvider!
	
	// MARK: Properties
	weak var accountTextField: UITextField!
	
	weak var delegate: NewChatViewControllerDelegate?
	var addressFormatter = NumberFormatter()
	static let invalidCharacters = CharacterSet.decimalDigits.inverted
	
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
	
	// MARK: - Lifecycle
	
    override func viewDidLoad() {
        super.viewDidLoad()
		navigationItem.title = String.adamantLocalized.newChat.title
		navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))
		navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
		
		navigationOptions = .Disabled
		
		form +++ Section() {
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
		<<< TextRow() {
			$0.tag = Rows.addressField.tag
			$0.cell.textField.placeholder = String.adamantLocalized.newChat.addressPlaceholder
			$0.cell.textField.keyboardType = .numberPad
			
			let prefix = UILabel()
			prefix.text = "U"
			prefix.textColor = UIColor.adamantPrimary
			prefix.font = UIFont.adamantPrimary(size: 17)
			prefix.sizeToFit()
			let view = UIView()
			view.addSubview(prefix)
			view.frame = prefix.frame
			prefix.frame = prefix.frame.offsetBy(dx: 0, dy: -1)
			$0.cell.textField.leftView = view
			$0.cell.textField.leftViewMode = .always
		}.cellSetup({ (cell, row) in
			cell.textField.font = UIFont.adamantPrimary(size: 17)
			cell.textField.textColor = UIColor.adamantPrimary
		}).cellUpdate({ (cell, row) in
			cell.textField.textColor = UIColor.adamantPrimary
			
			if let text = cell.textField.text {
				cell.textField.text = text.components(separatedBy: NewChatViewController.invalidCharacters).joined()
			}
		})
		
		if let row: TextRow = form.rowBy(tag: Rows.addressField.tag) {
			row.cell.textField.becomeFirstResponder()
		}
    }
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		
		if let row: TextRow = form.rowBy(tag: Rows.addressField.tag) {
			row.cell.textField.resignFirstResponder()
		}
	}
	
	
	// MARK: - IBActions
	
	@IBAction func done(_ sender: Any) {
		guard let row: TextRow = form.rowBy(tag: Rows.addressField.tag), let nums = row.value, nums.count > 0 else {
			dialogService.showToastMessage(String.adamantLocalized.newChat.specifyValidAddressMessage)
			return
		}
		
		var address = nums.uppercased()
		if !address.starts(with: "U") {
			address = "U\(address)"
		}
		
		startNewChat(with: address)
	}
	
	@IBAction func cancel(_ sender: Any) {
		dismiss(animated: true)
	}
	
	
	// MARK: - Other
	
	func startNewChat(with address: String, name: String? = nil) {
		guard AdamantUtilities.validateAdamantAddress(address: address) else {
			dialogService.showToastMessage(String.adamantLocalized.newChat.specifyValidAddressMessage)
			return
		}
		
		if let loggedAccount = accountService.account, loggedAccount.address == address {
			dialogService.showToastMessage(String.adamantLocalized.newChat.loggedUserAddressMessage)
			return
		}
		
		dialogService.showProgress(withMessage: nil, userInteractionEnable: false)
		
		accountsProvider.getAccount(byAddress: address) { result in
			switch result {
			case .success(let account):
				DispatchQueue.main.async {
					if let name = name, account.name == nil {
						account.name = name
						
						if let chatroom = account.chatroom, chatroom.title == nil {
							account.chatroom?.title = name
						}
					}
					
					self.delegate?.newChatController(self, didSelectAccount: account)
					self.dialogService.dismissProgress()
				}
				
			case .notFound:
				self.dialogService.showWarning(withMessage: String.localizedStringWithFormat(String.adamantLocalized.newChat.addressNotFoundFormat, address))
				
			case .serverError(let error):
				self.dialogService.showError(withMessage: String.localizedStringWithFormat(String.adamantLocalized.newChat.serverErrorFormat, String(describing: error)))
			}
		}
	}
	
	func startNewChat(with uri: AdamantUri) -> Bool {
		switch uri {
		case .address(address: let addr, params: let params):
			if let params = params?.first {
				switch params {
				case .label(label: let label):
					startNewChat(with: addr, name: label)
				}
			} else {
				startNewChat(with: addr)
			}
			
			return true
			
		default:
			return false
		}
	}
}


// MARK: - QR
extension NewChatViewController {
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


// MARK: - QRCodeReaderViewControllerDelegate
extension NewChatViewController: QRCodeReaderViewControllerDelegate {
	func reader(_ reader: QRCodeReaderViewController, didScanResult result: QRCodeReaderResult) {
		guard let uri = AdamantUriTools.decode(uri: result.value) else {
			dialogService.showWarning(withMessage: String.adamantLocalized.newChat.wrongQrError)
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
				reader.startScanning()
			}
			return
		}
		
		if startNewChat(with: uri) {
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


// MARK: - UIImagePickerControllerDelegate
extension NewChatViewController: UINavigationControllerDelegate, UIImagePickerControllerDelegate {
	func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
		dismiss(animated: true, completion: nil)
		
		guard let image = info[UIImagePickerControllerOriginalImage] as? UIImage else {
			return
		}
		
		if let cgImage = image.toCGImage(), let codes = EFQRCode.recognize(image: cgImage), codes.count > 0 {
			for aCode in codes {
				if let uri = AdamantUriTools.decode(uri: aCode) {
					if startNewChat(with: uri) {
						return
					}
				}
			}
			
			dialogService.showWarning(withMessage: String.adamantLocalized.newChat.wrongQrError)
		} else {
			dialogService.showWarning(withMessage: String.adamantLocalized.login.noQrError)
		}
	}
}


// MARK: - ButtonsStripe
extension NewChatViewController: ButtonsStripeViewDelegate {
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
