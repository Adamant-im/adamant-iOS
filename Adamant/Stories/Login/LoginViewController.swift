//
//  LoginViewController.swift
//  Adamant
//
//  Created by Anokhov Pavel on 05.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import TableKit

class LoginViewController: UIViewController {
	
	// MARK: - Dependencies
	
	var accountService: AccountService!
	var adamantCore: AdamantCore!
	var dialogService: DialogService!
	
	
	// MARK: - Rows
	
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
		if let header = UINib(nibName: "Header", bundle: nil).instantiate(withOwner: nil, options: nil).first as? UIView {
			tableView.tableHeaderView = header
		}
		
		
		// MARK: Login section
		
		let passphraseRow = TableRow<TextViewTableViewCell>(item: "")
		passphraseRow.on(.configure) { (options) in
			if let cell = options.cell {
				cell.placeHolder = "Passphrase"
				cell.textView.font = UIFont.adamantPrimary(size: 17)
				cell.textView.textAlignment = .center
				cell.textView.textColor = UIColor.adamantPrimary
				cell.textView.returnKeyType = .done
				cell.textView.delegate = self
				cell.delegate = self
			}
		}
		
		let loginRow = TableRow<ButtonTableViewCell>(item: "Login")
		loginRow.on(.click) { [weak self] options in self?.login() }
		
		let loginSection = TableSection(headerTitle: "Login", footerTitle: nil, rows: [passphraseRow, loginRow])
		tableDirector.append(section: loginSection)
		
		
		// MARK: NewPassphrase section
		
		let generateRow = TableRow<ButtonTableViewCell>(item: "Generate new Passphrase")
		generateRow.on(TableRowActionType.click) { [weak self] _ in self?.generateNewPassphrase() }
		
		let newAccSection = TableSection(headerTitle: "New Account", footerTitle: nil, rows: [generateRow])
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
			
			let warningRow = TableRow<MultilineLableTableViewCell>(item: "Save the passphrase for new Wallet and Messenger account. There is no login to enter Wallet, only the passphrase needed. If lost, no way to recover it.")
			warningRow.on(.shouldHighlight, handler: { _ -> Bool in
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
			
			self.tableDirector.sections[1].insert(rows: [warningRow, newPassphraseRow], at: 0)
			self.tableView.insertRows(at: [IndexPath(row: 0, section: 1), IndexPath(row: 1, section: 1)], with: .automatic)
			
			// Hack for a broken deselect animation
			let index = IndexPath(row: 2, section: 1)
			tableView.selectRow(at: index, animated: false, scrollPosition: .none)
			tableView.deselectRow(at: index, animated: true)
			tableView.scrollToRow(at: index, at: .top, animated: true)
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
				label.text = "Tap to save"
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
		
		alert.addAction(UIAlertAction(title: "Copy To Pasteboard", style: .default, handler: { _ in
			UIPasteboard.general.string = passphrase
			self.dialogService.showToastMessage("Copied To Pasteboard!")
		}))
		
		alert.addAction(UIAlertAction(title: "Save", style: .default, handler: { _ in
			let vc = UIActivityViewController(activityItems: [passphrase], applicationActivities: nil)
			vc.excludedActivityTypes = [.postToFacebook,
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
										.openInIBooks,
										.markupAsPDF]	// All of them
			self.present(vc, animated: true)
		}))
		
		alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
		
		present(alert, animated: true)
	}
	
	
	// MARK: Login
	func login() {
		guard let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? TextViewTableViewCell,
			var passphrase = cell.textView.text else {
				return
		}
		
		guard passphrase.count > 0 else {
			dialogService.showToastMessage("Enter your passphrase!")
			return
		}
		
		passphrase = passphrase.lowercased()
		
		dialogService.showProgress(withMessage: "Logging into ADAMANT", userInteractionEnable: false)
		
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
