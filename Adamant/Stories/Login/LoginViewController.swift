//
//  LoginViewController.swift
//  Adamant
//
//  Created by Anokhov Pavel on 04.03.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import Eureka

// MARK: - Localization
extension String.adamantLocalized {
	struct login {
		static let loggingInProgressMessage = NSLocalizedString("LoginScene.LoggingInProgress", comment: "Login: notify user that we are trying to log in")
		
		static let loginIntoPrevAccount = NSLocalizedString("LoginScene.LoginIntoAdamant", comment: "Login: Login into previous account with biometry or pincode")
		
		static let wrongQrError = NSLocalizedString("LoginScene.Error.WrongQr", comment: "Login: Notify user that scanned QR doesn't contains a passphrase.")
		static let noQrError = NSLocalizedString("LoginScene.Error.NoQrOnPhoto", comment: "Login: Notify user that picked photo doesn't contains a valid qr code with passphrase")
		static let noNetworkError = NSLocalizedString("LoginScene.Error.NoInternet", comment: "Login: No network error.")
		
		static let cameraNotAuthorized = NSLocalizedString("LoginScene.Error.AuthorizeCamera", comment: "Login: Notify user, that he disabled camera in settings, and need to authorize application.")
		static let cameraNotSupported = NSLocalizedString("LoginScene.Error.QrNotSupported", comment: "Login: Notify user that device not supported by QR reader")
		
		static let photolibraryNotAuthorized = NSLocalizedString("LoginScene.Error.AuthorizePhotolibrary", comment: "Login: User disabled access to photolibrary, he can authorize application in settings")
		
		static let emptyPassphraseAlert = NSLocalizedString("LoginScene.Error.NoPassphrase", comment: "Login: notify user that he is trying to login without a passphrase")
		
		private init() {}
	}
}


// MARK: - ViewController
class LoginViewController: FormViewController {
	
	// MARK: Rows & Sections
	
	enum Sections {
		case login
		case newAccount
		
		var localized: String {
			switch self {
			case .login:
				return NSLocalizedString("LoginScene.Section.Login", comment: "Login: login with existing passphrase section")
				
			case .newAccount:
				return NSLocalizedString("LoginScene.Section.NewAccount", comment: "Login: Create new account section")
			}
		}
		
		var tag: String {
			switch self {
			case .login: return "loginSection"
			case .newAccount: return "newAccount"
			}
		}
	}
	
	enum Rows {
		case passphrase
		case loginButton
		case loginWithQr
		case loginWithPin
		case newPassphrase
		case saveYourPassphraseAlert
		case tapToSaveHint
		case generateNewPassphraseButton
		
		var localized: String {
			switch self {
			case .passphrase:
				return NSLocalizedString("LoginScene.Row.Passphrase.Placeholder", comment: "Login: Passphrase placeholder")
				
			case .loginButton:
				return NSLocalizedString("LoginScene.Row.Login", comment: "Login: Login button")
				
			case .loginWithQr:
				return NSLocalizedString("LoginScene.Row.Qr", comment: "Login: Login with QR button.")
				
			case .loginWithPin:
				return NSLocalizedString("LoginScene.Row.Pincode", comment: "Login: Login with pincode button")
				
			case .saveYourPassphraseAlert:
				return NSLocalizedString("LoginScene.Row.SavePassphraseAlert", comment: "Login: security alert, notify user that he must save his new passphrase")
				
			case .generateNewPassphraseButton:
				return NSLocalizedString("LoginScene.Row.Generate", comment: "Login: generate new passphrase button")
				
			case .tapToSaveHint:
				return NSLocalizedString("LoginScene.Row.TapToSave", comment: "Login: a small hint for a user, that he can tap on passphrase to save it")
				
			case .newPassphrase:
				return ""
			}
		}
		
		var tag:String {
			switch self {
			case .passphrase: return "pass"
			case .loginButton: return "login"
			case .loginWithQr: return "qr"
			case .loginWithPin: return "pin"
			case .newPassphrase: return "newPass"
			case .saveYourPassphraseAlert: return "alert"
			case .generateNewPassphraseButton: return "generate"
			case .tapToSaveHint: return "hint"
			}
		}
	}
	
	
	// MARK: Dependencies
	
	var accountService: AccountService!
	var adamantCore: AdamantCore!
	var dialogService: DialogService!
	var localAuth: LocalAuthentication!
	
	
	// MARK: Properties
	private var hideNewPassphrase: Bool = true
	private var generatedPassphrases = [String]()
	private var firstTimeActive: Bool = true
	
	// MARK: Lifecycle
	
    override func viewDidLoad() {
        super.viewDidLoad()
		navigationOptions = RowNavigationOptions.Disabled
		
		// MARK: Header & Footer
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
		form +++ Section(Sections.login.localized) {
			$0.tag = Sections.login.tag
			
			$0.footer = { [weak self] in
				var footer = HeaderFooterView<UIView>(.callback {
					let view = ButtonsStripeView.adamantConfigured()
					
					var stripe: [StripeButtonType] = [.qrCameraReader, .qrPhotoReader]
					
					if let accountService = self?.accountService, accountService.hasStayInAccount {
						if accountService.useBiometry, let button = self?.localAuth.biometryType.stripeButtonType {
							stripe.append(button)
						} else {
							stripe.append(.pinpad)
						}
					}
					
					view.stripe = stripe
					view.delegate = self
					
					return view
				})
				
				footer.height = { ButtonsStripeView.adamantDefaultHeight }
				
				return footer
			}()
		}
		
		// Passphrase row
		<<< PasswordRow() {
			$0.tag = Rows.passphrase.tag
			$0.placeholder = Rows.passphrase.localized
			$0.keyboardReturnType = KeyboardReturnTypeConfiguration(nextKeyboardType: .go, defaultKeyboardType: .go)
		}
			
		// Login with passphrase row
		<<< ButtonRow() {
			$0.tag = Rows.loginButton.tag
			$0.title = Rows.loginButton.localized
			$0.disabled = Condition.function([Rows.passphrase.tag], { form -> Bool in
				guard let row: PasswordRow = form.rowBy(tag: Rows.passphrase.tag), row.value != nil else {
					return true
				}
				return false
			})
		}.onCellSelection({ [weak self] (cell, row) in
			guard let row: PasswordRow = self?.form.rowBy(tag: Rows.passphrase.tag), let passphrase = row.value else {
				return
			}
			
			self?.loginWith(passphrase: passphrase)
		}).cellSetup({ (cell, row) in
			cell.textLabel?.font = UIFont.adamantPrimary(size: 17)
		}).cellUpdate({ (cell, row) in
			cell.textLabel?.textColor = UIColor.adamantPrimary
		})
		
		
		// MARK: New account section
		form +++ Section(Sections.newAccount.localized) {
			$0.tag = Sections.newAccount.tag
		}
		
		// Alert
		<<< TextAreaRow() {
			$0.tag = Rows.saveYourPassphraseAlert.tag
			$0.textAreaHeight = .dynamic(initialTextViewHeight: 44)
			$0.value = Rows.saveYourPassphraseAlert.localized
			$0.hidden = Condition.function([], { [weak self] form -> Bool in
				return self?.hideNewPassphrase ?? false
			})
			}.cellUpdate({ (cell, row) in
				cell.textView.textAlignment = .center
				cell.textView.font = UIFont.adamantPrimary(size: 14)
				cell.textView.textColor = UIColor.adamantPrimary
				cell.textView.isSelectable = false
				cell.textView.isEditable = false
			})
		
		// New genegated passphrase
		<<< PassphraseRow() {
			$0.tag = Rows.newPassphrase.tag
			$0.cell.tip = Rows.tapToSaveHint.localized
			$0.cell.height = {96.0}
			$0.hidden = Condition.function([], { [weak self] form -> Bool in
				return self?.hideNewPassphrase ?? true
			})
		}.cellUpdate({ (cell, row) in
			cell.passphraseLabel.font = UIFont.adamantPrimary(size: 19)
			cell.passphraseLabel.textColor = UIColor.adamantPrimary
			cell.passphraseLabel.textAlignment = .center
		
			cell.tipLabel.font = UIFont.adamantPrimary(size: 12)
			cell.tipLabel.textColor = UIColor.adamantSecondary
			cell.tipLabel.textAlignment = .center
		}).onCellSelection({ [weak self] (cell, row) in
			guard let passphrase = self?.generatedPassphrases.last, let dialogService = self?.dialogService else {
				return
			}
			
			if let indexPath = row.indexPath, let tableView = self?.tableView {
				tableView.deselectRow(at: indexPath, animated: true)
			}
			
			let encodedPassphrase = AdamantUriTools.encode(request: AdamantUri.passphrase(passphrase: passphrase))
			dialogService.presentShareAlertFor(string: encodedPassphrase,
											   types: [.copyToPasteboard, .share, .generateQr(sharingTip: nil)],
											   excludedActivityTypes: ShareContentType.passphrase.excludedActivityTypes,
											   animated: true,
											   completion: nil)
		})
		
		<<< ButtonRow() {
			$0.tag = Rows.generateNewPassphraseButton.tag
			$0.title = Rows.generateNewPassphraseButton.localized
		}.onCellSelection({ [weak self] (cell, row) in
			self?.generateNewPassphrase()
		}).cellSetup({ (cell, row) in
			cell.textLabel?.font = UIFont.adamantPrimary(size: 17)
			cell.textLabel?.textColor = UIColor.adamantPrimary
		}).cellUpdate({ (cell, row) in
			cell.textLabel?.textColor = UIColor.adamantPrimary
		})
		
		
		// MARK: tableView position tuning
		if let row: PasswordRow = form.rowBy(tag: Rows.passphrase.tag) {
			NotificationCenter.default.addObserver(forName: Notification.Name.UITextFieldTextDidBeginEditing, object: row.cell.textField, queue: nil) { [weak self] _ in
				guard let tableView = self?.tableView, let indexPath = self?.form.rowBy(tag: Rows.loginButton.tag)?.indexPath else {
					return
				}
				
				DispatchQueue.main.async {
					tableView.scrollToRow(at: indexPath, at: .none, animated: true)
				}
			}
		}
		
		// MARK: Requesting biometry onActive
		NotificationCenter.default.addObserver(forName: Notification.Name.UIApplicationDidBecomeActive, object: nil, queue: OperationQueue.main) { [weak self] _ in
			if let firstTimeActive = self?.firstTimeActive, firstTimeActive,
				let accountService = self?.accountService, accountService.hasStayInAccount, accountService.useBiometry {
				self?.loginWithBiometry()
				self?.firstTimeActive = false
			}
		}
    }
}


// MARK: - Login functions
extension LoginViewController {
	func loginWith(passphrase: String) {
		guard AdamantUtilities.validateAdamantPassphrase(passphrase: passphrase) else {
			dialogService.showError(withMessage: AccountServiceError.wrongPassphrase.localized)
			return
		}
		
		dialogService.showProgress(withMessage: String.adamantLocalized.login.loggingInProgressMessage, userInteractionEnable: false)
		
		if generatedPassphrases.contains(passphrase) {
			DispatchQueue.global(qos: .utility).async { [weak self] in
				self?.createAccountAndLogin(passphrase: passphrase)
			}
		} else {
			DispatchQueue.global(qos: .utility).async { [weak self] in
				self?.loginIntoExistingAccount(passphrase: passphrase)
			}
		}
	}
	
	func generateNewPassphrase() {
		let passphrase = adamantCore.generateNewPassphrase()
		generatedPassphrases.append(passphrase)
		
		hideNewPassphrase = false
		
		form.rowBy(tag: Rows.saveYourPassphraseAlert.tag)?.evaluateHidden()
		
		if let row: PassphraseRow = form.rowBy(tag: Rows.newPassphrase.tag) {
			row.value = passphrase
			row.updateCell()
			row.evaluateHidden()
		}
		
		if let row = form.rowBy(tag: Rows.generateNewPassphraseButton.tag), let indexPath = row.indexPath {
			tableView.scrollToRow(at: indexPath, at: .none, animated: true)
		}
	}
	
	// MARK: Login helpers
	private func createAccountAndLogin(passphrase: String) {
		accountService.createAccountWith(passphrase: passphrase, completion: { [weak self] result in
			switch result {
			case .success:
				self?.loginIntoExistingAccount(passphrase: passphrase)
				
			case .failure(let error):
				self?.dialogService.showError(withMessage: error.localized)
			}
		})
	}
	
	private func loginIntoExistingAccount(passphrase: String) {
		accountService.loginWith(passphrase: passphrase, completion: { [weak self] result in
			switch result {
			case .success(_):
				if let nav = self?.navigationController {
					nav.popViewController(animated: true)
				} else {
					self?.dismiss(animated: true, completion: nil)
				}
				
				self?.dialogService.dismissProgress()
				
			case .failure(let error):
				self?.dialogService.showError(withMessage: error.localized)
			}
		})
	}
}


// MARK: - Button stripe
extension LoginViewController: ButtonsStripeViewDelegate {
	func buttonsStripe(_ stripe: ButtonsStripeView, didTapButton button: StripeButtonType) {
		switch button {
		case .pinpad:
			loginWithPinpad()
			
		case .touchID, .faceID:
			loginWithBiometry()
			
		case .qrCameraReader:
			loginWithQrFromCamera()
			
		case .qrPhotoReader:
			loginWithQrFromLibrary()
		}
	}
}
