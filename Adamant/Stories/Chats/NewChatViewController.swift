//
//  NewChatViewController.swift
//  Adamant
//
//  Created by Anokhov Pavel on 21.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit

// MARK: - Localization
extension String.adamantLocalized {
	struct newChat {
		static let addressPlaceholder = NSLocalizedString("newChat.address-placeholder", comment: "Recipient address placeholder. Note that address text field always shows U letter, so you can left this line blank.")
		
		static let specifyValidAddressMessage = NSLocalizedString("newChat.specify-valid-address-message", comment: "Please specify valid recipient address")
		static let loggedUserAddressMessage = NSLocalizedString("newChat.logged-user-address-message", comment: "Notify user that he can't start chat with himself")
		
		static let addressNotFoundFormat = NSLocalizedString("newChat.address-not-found-format", comment: "Address %@ not found")
		static let serverErrorFormat = NSLocalizedString("chat.server-error-format", comment: "Remote server error: %@")
		
		private init() { }
	}
}


// MARK: - Delegate
protocol NewChatViewControllerDelegate: class {
	func newChatController(_ controller: NewChatViewController, didSelectAccount account: CoreDataAccount)
}


// MARK: -
class NewChatViewController: UITableViewController {
	// MARK: - Dependencies
	var dialogService: DialogService!
	var accountService: AccountService!
	var accountsProvider: AccountsProvider!
	
	
	// MARK: - Properties
	@IBOutlet weak var accountTextField: UITextField!
	
	weak var delegate: NewChatViewControllerDelegate?
	var addressFormatter = NumberFormatter()
	let invalidCharacters = CharacterSet(charactersIn: "U0123456789").inverted
	
	// MARK: - Lifecycle
	
    override func viewDidLoad() {
        super.viewDidLoad()
		accountTextField.textColor = UIColor.adamantPrimary
		accountTextField.delegate = self
		accountTextField.text = ""
		accountTextField.placeholder = String.adamantLocalized.newChat.addressPlaceholder
		
		let prefix = UILabel()
		prefix.text = "U"
		prefix.textColor = UIColor.adamantPrimary
		prefix.font = accountTextField.font
		prefix.sizeToFit()
		let view = UIView()
		view.addSubview(prefix)
		view.frame = prefix.frame
		prefix.frame = prefix.frame.offsetBy(dx: 0, dy: -1)
		accountTextField.leftView = view
		accountTextField.leftViewMode = .always
		
		accountTextField.becomeFirstResponder()
    }
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		accountTextField.resignFirstResponder()
	}
	
	
	// MARK: - IBActions
	
	@IBAction func done(_ sender: UITextField) {
		guard let nums = accountTextField.text, nums.count > 1 else {
			dialogService.showToastMessage(String.adamantLocalized.newChat.specifyValidAddressMessage)
			return
		}
		
		var address = nums.uppercased()
		if let u = address.first, u != "U" {
			address = "U\(address)"
		}
		
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
					self.delegate?.newChatController(self, didSelectAccount: account)
					self.dialogService.dismissProgress()
				}
				
			case .notFound:
				self.dialogService.showError(withMessage: String.localizedStringWithFormat(String.adamantLocalized.newChat.addressNotFoundFormat, address))
				
			case .serverError(let error):
				self.dialogService.showError(withMessage: String(describing: error))
			}
		}
	}
	
	@IBAction func cancel(_ sender: Any) {
		dismiss(animated: true)
	}
}


// MARK: - UITextFieldDelegate
extension NewChatViewController: UITextFieldDelegate {
	func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
		if string.rangeOfCharacter(from: invalidCharacters, options: [], range: string.startIndex ..< string.endIndex) == nil {
			if string.contains("U") {
				let cleaned = string.replacingOccurrences(of: "U", with: "")
				if let selectedRange = textField.selectedTextRange {
					textField.replace(selectedRange, withText: cleaned)
				} else {
					textField.text = cleaned
				}
				
				return false
			}
			
			return true
		} else {
			return false
		}
	}
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		done(textField)
		return false
	}
}
