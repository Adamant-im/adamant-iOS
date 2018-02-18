//
//  LoginViewController.swift
//  Adamant
//
//  Created by Anokhov Pavel on 05.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import TableKit


// MARK: - Localization
extension String.adamantLocalized {
	struct login {
		static let passphrasePlaceholder = NSLocalizedString("passphrase", comment: "Login: Passphrase placeholder")
		static let loggingInProgressMessage = NSLocalizedString("Logging in", comment: "Login: notify user that we a logging in.")
		
		static let wrongPassphraseError = NSLocalizedString("Wrong passphrase!", comment: "Login: user typed in wrong passphrase.")
		static let noNetworkError = NSLocalizedString("No connection with The Internet", comment: "Login: No network error.")
		
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
		case saveYourPassphraseAlert
		case generateNewPassphraseButton
		case tapToSaveHint
		
		var localized: String {
			switch self {
			case .loginButton:
				return NSLocalizedString("Login", comment: "Login: Login button")
				
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
		
		let loginSection = TableSection(headerTitle: Sections.passphrase.localized, footerTitle: nil, rows: [passphraseRow, loginRow])
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
		
		let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
		
		alert.addAction(UIAlertAction(title: String.adamantLocalized.alert.copyToPasteboard, style: .default, handler: { _ in
			UIPasteboard.general.string = passphrase
			self.dialogService.showToastMessage(String.adamantLocalized.alert.copiedToPasteboardNotification)
		}))
		
		// Exclude all sharing activities
		var excluded: [UIActivityType] = [.postToFacebook,
										 .postToTwitter,
										 .postToWeibo,
										 .message,
										 .mail,
										 .assignToContact,
										 .saveToCameraRoll,
										 .addToReadingList,
										 .postToFlickr,
										 .postToVimeo,
										 .postToTencentWeibo,
										 .airDrop,
										 .openInIBooks]
		
		if #available(iOS 11.0, *) {
			excluded.append(.markupAsPDF)
		}
		
		alert.addAction(UIAlertAction(title: String.adamantLocalized.alert.save, style: .default, handler: { _ in
			let vc = UIActivityViewController(activityItems: [passphrase], applicationActivities: nil)
			vc.excludedActivityTypes = excluded
			self.present(vc, animated: true)
		}))
		
		alert.addAction(UIAlertAction(title: String.adamantLocalized.alert.cancel, style: .cancel, handler: nil))
		
		present(alert, animated: true)
	}
	
	
	// MARK: Login
	func login() {
		guard let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? TextViewTableViewCell,
			var passphrase = cell.textView.text else {
				return
		}
		
		guard passphrase.count > 0 else {
			dialogService.showToastMessage(String.adamantLocalized.login.emptyPassphraseAlert)
			return
		}
		
		passphrase = passphrase.lowercased()
		
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
