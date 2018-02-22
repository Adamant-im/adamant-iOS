//
//  LoginViewController.swift
//  Adamant
//
//  Created by Anokhov Pavel on 05.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import TableKit
import QRCodeReader
import AVFoundation


// MARK: - Localization
extension String.adamantLocalized {
	struct login {
		static let passphrasePlaceholder = NSLocalizedString("passphrase", comment: "Login: Passphrase placeholder")
		static let loggingInProgressMessage = NSLocalizedString("Logging in", comment: "Login: notify user that we a logging in.")
		
		static let wrongPassphraseError = NSLocalizedString("Wrong passphrase!", comment: "Login: user typed in wrong passphrase.")
		static let wrongQrError = NSLocalizedString("QR code does not contains a valid passphrase.", comment: "Login: Notify user that scanned QR doesn't contains passphrase.")
		static let noNetworkError = NSLocalizedString("No connection with The Internet", comment: "Login: No network error.")
		
		static let cameraNotAuthorized = NSLocalizedString("You need to authorize Adamant to use device's Camera", comment: "Login: Notify user, that he disabled camera in settings, and need to authorize application.")
		static let cameraNotSupported = NSLocalizedString("QR codes reading not supported by the current device", comment: "Login: Notify user that device not supported by QR reader")
		
		static let emptyPassphraseAlert = NSLocalizedString("Enter a passphrase!", comment: "Login: notify user that he is trying to login without a passphrase")
		
		private init() {}
	}
}


// MARK: -
class LoginViewController: UIViewController {
	
	enum Sections {
		case passphrase
		case newAccount
		
		var localized: String {
			switch self {
			case .passphrase:
				return NSLocalizedString("Login", comment: "Login: login with existing passphrase section")
				
			case .newAccount:
				return NSLocalizedString("New account", comment: "Login: Create new account section")
			}
		}
	}
	
	enum Rows {
		case loginButton
		case loginWithQr
		case saveYourPassphraseAlert
		case generateNewPassphraseButton
		case tapToSaveHint
		
		var localized: String {
			switch self {
			case .loginButton:
				return NSLocalizedString("Login", comment: "Login: Login button")
				
			case .loginWithQr:
				return NSLocalizedString("QR", comment: "Login: Login with QR button.")
				
			case .saveYourPassphraseAlert:
				return NSLocalizedString("Save the passphrase for new Wallet and Messenger account. There is no login to enter Wallet, only the passphrase needed. If lost, no way to recover it", comment: "Login: security alert, notify user that he must save his new passphrase")
				
			case .generateNewPassphraseButton:
				return NSLocalizedString("Generate new passphrase", comment: "Login: generate new passphrase button")
				
			case .tapToSaveHint:
				return NSLocalizedString("Tap to save", comment: "Login: a small hint for a user, that he can tap on passphrase to save it")
			}
		}
	}
	
	// MARK: - Dependencies
	var accountService: AccountService!
	var adamantCore: AdamantCore!
	var dialogService: DialogService!
	
	
	// MARK: - Properties
	@IBOutlet var tableView: UITableView!
	var tableDirector: TableDirector!
	private var newPassphraseRowsIsVisible = false
	private var generatedPassphrases = [String]()
	
	// MARK: - Lifecycle
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		
		// MARK: TableView configuration
		tableDirector = TableDirector(tableView: tableView)
		if let header = UINib(nibName: "LoginHeader", bundle: nil).instantiate(withOwner: nil, options: nil).first as? UIView {
			tableView.tableHeaderView = header
			
			if let label = header.viewWithTag(888) as? UILabel {
				label.text = String.adamantLocalized.shared.productName
				label.textColor = UIColor.adamantPrimary
			}
		}
		
		if let footer = UINib(nibName: "LoginFooter", bundle: nil).instantiate(withOwner: nil, options: nil).first as? UIView {
			if let label = footer.viewWithTag(555) as? UILabel {
				label.text = AdamantUtilities.applicationVersion
				label.textColor = UIColor.adamantPrimary
				tableView.tableFooterView = footer
			}
		}
		
		
		// MARK: Login section
		
		let passphraseRow = TableRow<TextViewTableViewCell>(item: "")
		passphraseRow.on(.configure) { (options) in
			if let cell = options.cell {
				cell.placeHolder = String.adamantLocalized.login.passphrasePlaceholder
				cell.textView.font = UIFont.adamantPrimary(size: 17)
				cell.textView.textAlignment = .center
				cell.textView.textColor = UIColor.adamantPrimary
				cell.textView.returnKeyType = .done
				cell.textView.delegate = self
				cell.delegate = self
			}
		}
		
		let loginRow = TableRow<ButtonTableViewCell>(item: Rows.loginButton.localized)
		loginRow.on(.click) { [weak self] options in self?.login() }
		
		let loginWithQrRow = TableRow<ButtonTableViewCell>(item: Rows.loginWithQr.localized)
		loginWithQrRow.on(.click) { [weak self] _ in self?.loginWithQr() }
		
		let loginSection = TableSection(headerTitle: Sections.passphrase.localized, footerTitle: nil, rows: [passphraseRow, loginRow, loginWithQrRow])
		tableDirector.append(section: loginSection)
		
		
		// MARK: NewPassphrase section
		
		let generateRow = TableRow<ButtonTableViewCell>(item: Rows.generateNewPassphraseButton.localized)
		generateRow.on(TableRowActionType.click) { [weak self] _ in self?.generateNewPassphrase() }
		
		let newAccSection = TableSection(headerTitle: Sections.newAccount.localized, footerTitle: nil, rows: [generateRow])
		tableDirector.append(section: newAccSection)
		
		
		// MARK: Notifications
		
		NotificationCenter.default.addObserver(forName: NSNotification.Name.UIKeyboardWillShow, object: nil, queue: nil, using: keyboardWillShow)
		NotificationCenter.default.addObserver(forName: NSNotification.Name.UIKeyboardWillHide, object: nil, queue: nil, using: keyboardWillHide)
    }
	
	
	
	func generateNewPassphrase() {
		let passphrase = adamantCore.generateNewPassphrase()
		generatedPassphrases.append(passphrase)
		
		if !newPassphraseRowsIsVisible {
			newPassphraseRowsIsVisible = true
			
			let alertRow = TableRow<MultilineLableTableViewCell>(item: Rows.saveYourPassphraseAlert.localized)
			alertRow.on(.shouldHighlight, handler: { _ -> Bool in
				return false
			}).on(.configure, handler: { options in
				if let label = options.cell?.multilineLabel {
					label.textAlignment = .center
					label.font = UIFont.adamantPrimary(size: 14)
					label.textColor = UIColor.adamantPrimary
				}
				options.cell?.layoutSubviews()
			})
			
			let newPassphraseRow = createPassphraseRow(passphrase: passphrase)
			
			if let indexPath = tableView.indexPathForSelectedRow {
				tableView.deselectRow(at: indexPath, animated: false)
			}
			
			self.tableDirector.sections[1].insert(rows: [alertRow, newPassphraseRow], at: 0)
			self.tableView.insertRows(at: [IndexPath(row: 0, section: 1), IndexPath(row: 1, section: 1)], with: .automatic)
			
			// Hack for a broken deselect animation
			let index = IndexPath(row: 2, section: 1)
			tableView.selectRow(at: index, animated: false, scrollPosition: .none)
			tableView.deselectRow(at: index, animated: true)
			tableView.scrollToRow(at: index, at: .none, animated: true)
		} else {
			let newPassphraseRow = createPassphraseRow(passphrase: passphrase)
			
			tableDirector.sections[1].replace(rowAt: 1, with: newPassphraseRow)
			tableView.reloadRows(at: [IndexPath(row: 1, section: 1)], with: .fade)
		}
	}
	
	private func createPassphraseRow(passphrase: String) -> Row {
		let row = TableRow<MultilineLableTableViewCell>(item: passphrase).on(.click, handler: { [weak self] _ in
			self?.presentPassphraseActions()
		}).on(.configure) { options in
			if let label = options.cell?.multilineLabel {
				label.font = UIFont.adamantPrimary(size: 19)
				label.textColor = UIColor.adamantPrimary
				label.textAlignment = .center
			}
			if let label = options.cell?.detailsMultilineLabel {
				label.font = UIFont.adamantPrimary(size: 12)
				label.textColor = UIColor.adamantSecondary
				label.text = Rows.tapToSaveHint.localized
				label.textAlignment = .center
			}
		}
		
		return row
	}
	
	
	// MARK: Saving new passphrase
	func presentPassphraseActions() {
		guard let passphrase = generatedPassphrases.last else {
			return
		}
		
		dialogService.presentShareAlertFor(string: passphrase,
										   types: [.copyToPasteboard, .share, .generateQr],
										   excludedActivityTypes: ShareContentType.passphrase.excludedActivityTypes,
										   animated: true,
										   completion: nil)
	}
	
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
}


// MARK: Login
extension LoginViewController {
	func login() {
		guard let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? TextViewTableViewCell,
			let passphrase = cell.textView.text else {
			return
		}
		
		guard passphrase.count > 0 else {
			dialogService.showToastMessage(String.adamantLocalized.login.emptyPassphraseAlert)
			return
		}
		
		loginWith(passphrase: passphrase.lowercased())
	}
	
	func loginWithQr() {
		switch AVCaptureDevice.authorizationStatus(for: .video) {
		case .authorized:
			present(qrReader, animated: true, completion: nil)
			
		case .notDetermined:
			AVCaptureDevice.requestAccess(for: .video) { [weak self] (granted: Bool) in
				if granted, let qrReader = self?.qrReader {
					self?.present(qrReader, animated: true, completion: nil)
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
	
	private func loginWith(passphrase: String) {
		dialogService.showProgress(withMessage: String.adamantLocalized.login.loggingInProgressMessage, userInteractionEnable: false)
		
		// Dialog service currently presenting progress async. So if AccountService fails instantly, progress will be presented AFTER fail.
		DispatchQueue.global(qos: .utility).async {
			if self.generatedPassphrases.contains(passphrase) {
				self.accountService.createAccount(with: passphrase) { (_, error) in
					if let error = error {
						self.dialogService.showError(withMessage: error.message)
					} else {
						self.dialogService.dismissProgress()
					}
				}
			} else {
				self.accountService.login(with: passphrase) { (_, error) in
					if let error = error {
						if let internalError = error.internalError as? ApiServiceError {
							switch internalError {
							case .accountNotFound:
								self.dialogService.showError(withMessage: String.adamantLocalized.login.wrongPassphraseError)
								return
								
							case .networkError(error: _):
								self.dialogService.showError(withMessage: String.adamantLocalized.login.noNetworkError)
								return
								
							default:
								break
							}
						}
						
						self.dialogService.showError(withMessage: error.message)
					} else {
						self.dialogService.dismissProgress()
					}
				}
			}
		}
	}
}


// MARK: - QR
extension LoginViewController: QRCodeReaderViewControllerDelegate {
	func reader(_ reader: QRCodeReaderViewController, didScanResult result: QRCodeReaderResult) {
		guard AdamantUtilities.validateAdamantPassphrase(passphrase: result.value) else {
			dialogService.showError(withMessage: String.adamantLocalized.login.wrongQrError)
			return
		}
		
		reader.stopScanning()
		reader.dismiss(animated: true, completion: nil)
		loginWith(passphrase: result.value)
	}
	
	func readerDidCancel(_ reader: QRCodeReaderViewController) {
		reader.dismiss(animated: true, completion: nil)
	}
	
	private func checkCameraPermissions() -> Bool {
		
		
		do {
			return try QRCodeReader.supportsMetadataObjectTypes()
		} catch let error as NSError {
			let alert: UIAlertController
			
			switch error.code {
			case -11852:
				alert = UIAlertController(title: nil, message: String.adamantLocalized.login.cameraNotAuthorized, preferredStyle: .alert)
				
				alert.addAction(UIAlertAction(title: String.adamantLocalized.alert.settings, style: .default, handler: { (_) in
					DispatchQueue.main.async {
						if let settingsURL = URL(string: UIApplicationOpenSettingsURLString) {
							UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
						}
					}
				}))
				
				alert.addAction(UIAlertAction(title: String.adamantLocalized.alert.cancel, style: .cancel, handler: nil))
			default:
				alert = UIAlertController(title: nil, message: String.adamantLocalized.login.cameraNotSupported, preferredStyle: .alert)
				alert.addAction(UIAlertAction(title: String.adamantLocalized.alert.ok, style: .cancel, handler: nil))
			}
			
			present(alert, animated: true, completion: nil)
			
			return false
		}
	}
}


// MARK: - Passphrase cell delegates
extension LoginViewController: TextViewTableViewCellDelegate {
	func cellDidChangeHeight(_ textView: TextViewTableViewCell, height: CGFloat) {
		tableView.beginUpdates()
		tableView.endUpdates()
	}
}

extension LoginViewController: UITextViewDelegate {
	func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
		if (text == "\n") {
			textView.resignFirstResponder()
			login()
			return false
		} else {
			return true
		}
	}
}


// MARK: - Keyboard
extension LoginViewController {
	func keyboardWillShow(notification: Notification) {
		guard let keyboard = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
			return
		}
		
		var contentInset: UIEdgeInsets = tableView.contentInset
		contentInset.bottom = keyboard.size.height
		tableView.contentInset = contentInset
		tableView.scrollIndicatorInsets = contentInset
		
		DispatchQueue.main.async {
			self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
		}
	}
	
	func keyboardWillHide(notification: Notification) {
		tableView.contentInset = UIEdgeInsets.zero
		tableView.scrollIndicatorInsets = UIEdgeInsets.zero
	}
}
