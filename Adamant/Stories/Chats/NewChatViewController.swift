//
//  NewChatViewController.swift
//  Adamant
//
//  Created by Anokhov Pavel on 21.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit

protocol NewChatViewControllerDelegate: class {
	func newChatController(_ controller: NewChatViewController, didSelectAccount account: CoreDataAccount)
}

class NewChatViewController: UITableViewController {
	// MARK: - Dependencies
	var dialogService: DialogService!
	var accountService: AccountService!
	var accountsProvider: AccountsProvider!
	
	
	// MARK: - Properties
	@IBOutlet weak var accountTextField: UITextField!
	
	weak var delegate: NewChatViewControllerDelegate?
	
	
	// MARK: - Lifecycle
	
    override func viewDidLoad() {
        super.viewDidLoad()
		accountTextField.textColor = UIColor.adamantPrimary
		accountTextField.delegate = self
		accountTextField.text = ""
		accountTextField.becomeFirstResponder()
    }
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		accountTextField.resignFirstResponder()
	}
	
	
	// MARK: - IBActions
	
	@IBAction func done(_ sender: Any) {
		guard let nums = accountTextField.text, nums.count > 1 else {
			dialogService.showToastMessage("Please specify valid recipient address")
			return
		}
		
		var address = nums.uppercased()
		if let u = address.first, u != "U" {
			address = "U\(address)"
		}
		
		guard AdamantUtilities.validateAdamantAddress(address: address) else {
			dialogService.showToastMessage("Please specify valid recipient address")
			return
		}
		
		if let loggedAccount = accountService.account, loggedAccount.address == address {
			dialogService.showToastMessage("You don't need encrypted anonymous chat to talk to yourself.")
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
				self.dialogService.showError(withMessage: "Address \(address) not found")
				
			case .serverError(let error):
				// TODO: message
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
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		done(textField)
		return false
	}
}
