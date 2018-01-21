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

class NewChatViewController: UIViewController {
	
	// MARK: - Properties
	
	@IBOutlet weak var accountTextField: UITextField!
	@IBOutlet weak var messageLabel: UILabel!
	
	weak var delegate: NewChatViewControllerDelegate?
	
	
	// MARK: - Lifecycle
	
    override func viewDidLoad() {
        super.viewDidLoad()
		messageLabel.isHidden = true
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
			messageLabel.text = "Please specify valid recipient address"
			messageLabel.isHidden = false
			return
		}
		
		var address = nums.uppercased()
		if let u = address.first, u != "U" {
			address = "U\(address)"
		}
		
		if !AdamantUtilities.validateAdamantAddress(address: address) {
			messageLabel.text = "Please specify valid recipient address"
			messageLabel.isHidden = false
			return
		}
		
		delegate?.newChatController(self, didSelectedAddress: address)
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
	
	func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
		messageLabel.isHidden = true
		return true
	}
}
