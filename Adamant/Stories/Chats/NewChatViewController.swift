//
//  NewChatViewController.swift
//  Adamant
//
//  Created by Anokhov Pavel on 21.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit

protocol NewChatViewControllerDelegate: class {
	func newChatController(_ controller: NewChatViewController, didSelectedAddress address: String)
}

class NewChatViewController: UITableViewController {
	// MARK: - Dependencies
	var dialogService: DialogService!
	var apiService: ApiService!
	
	
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
		
		if !AdamantUtilities.validateAdamantAddress(address: address) {
			dialogService.showToastMessage("Please specify valid recipient address")
			return
		}
		
		dialogService.showProgress(withMessage: nil, userInteractionEnable: false)
		
		apiService.getPublicKey(byAddress: address) { (publicKey, error) in
			if publicKey != nil {
				DispatchQueue.main.async {
					self.delegate?.newChatController(self, didSelectedAddress: address)
					self.dialogService.dismissProgress()
				}
			}
			
			else if let error = error {
				DispatchQueue.main.async {
					self.dialogService.showError(withMessage: error.message)
				}
			}
			
			else {
				DispatchQueue.main.async {
					self.dialogService.showError(withMessage: "Address \(address) not found")
				}
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
