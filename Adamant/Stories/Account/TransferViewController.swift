//
//  TransferViewController.swift
//  Adamant-ios
//
//  Created by Anokhov Pavel on 09.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import Eureka
import FTIndicator

class TransferViewController: FormViewController {
	private struct Row {
		static let Amount = Row("amount")
		static let Recipient = Row("recipient")
		static let Fee = Row("fee")
		static let Total = Row("total")
		static let SendButton = Row("send")
		
		let tag: String
		private init(_ tag: String) {
			self.tag = tag
		}
	}
	
	
	// MARK: - Dependencies
	var apiService: ApiService!
	var loginService: LoginService!
	
	
	// MARK: - Properties
	let defaultFee = 0.5
	var account: Account?
	
	private(set) var totalAmount: Double? = nil
	
	
	// MARK: - IBOutlets
	@IBOutlet weak var sendButton: UIBarButtonItem!
	
	
	// MARK: - Lifecycle
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		// MARK: - Wallet section
		if let account = account {
			let balance = Double(account.balance) * AdamantFormatters.currencyShift
			let toTransfer = balance - defaultFee > 0 ? balance - defaultFee : 0.0
			
			sendButton.isEnabled = toTransfer > 0.0
			
			form +++ Section("Your wallet")
			<<< DecimalRow() {
				$0.title = "Balance"
				$0.value = balance
				$0.disabled = true
			}
			<<< DecimalRow() {
				$0.title = "Max to transfer"
				$0.value = toTransfer
				$0.disabled = true
			}
		}
		
		// MARK: - Transfer section
		form +++ Section("transfer info")
		
		<<< TextRow() {
			$0.title = "Address"
			$0.placeholder = "of the recipient"
			$0.tag = Row.Recipient.tag
			$0.add(rule: RuleClosure<String>(closure: { value -> ValidationError? in
				if let value = value?.uppercased(),
					AdamantFormatters.validateAdamantAddress(address: value) {
					return nil
				} else {
					return ValidationError(msg: "Incorrect address")
				}
			}))
			$0.validationOptions = .validatesOnBlur
		}.cellUpdate({ (cell, row) in
			cell.titleLabel?.textColor = row.isValid ? .black : .red
		})
		<<< DecimalRow() {
			$0.title = "Amount"
			$0.placeholder = "to send"
			$0.tag = Row.Amount.tag
		}.onChange(amountChanged)
		<<< DecimalRow() {
			$0.title = "Transaction fee"
			$0.value = defaultFee
			$0.tag = Row.Fee.tag
			$0.disabled = true
		}
		<<< DecimalRow() {
			$0.title = "Amount including fee"
			$0.value = nil
			$0.tag = Row.Total.tag
			$0.disabled = true
		}
		<<< ButtonRow() {
			$0.title = "Send funds"
			$0.tag = Row.SendButton.tag
			$0.disabled = Condition.function([Row.Amount.tag], { [weak self] form -> Bool in
				guard let balance = self?.account?.balance,
					let fee = self?.defaultFee,
					let row: DecimalRow = form.rowBy(tag: Row.Amount.tag),
					let amount = row.value else {
					return true
				}
				
				return amount + fee > (Double(balance) * AdamantFormatters.currencyShift)
			})
		}
		
		
		// MARK: - UI
		
		if let font = UIFont(name: "Exo 2", size: 17) {
			navigationAccessoryView.tintColor = UIColor.adamantPrimary

			for row in form.allRows {
				row.baseCell?.textLabel?.font = font
				row.baseCell?.textLabel?.textColor = UIColor.adamantPrimary
				row.baseCell?.tintColor = UIColor.adamantPrimary
				
				// TODO: Not working. Somehow font get's dropped at runtime.
//				if let cell = row.baseCell as? TextFieldCell {
//					cell.textField.font = font
//					cell.textField.textColor = color
//				}
			}
		}
		
		let button: ButtonRow? = form.rowBy(tag: Row.SendButton.tag)
		button?.evaluateDisabled()
    }
	
	
	// MARK: - Form Events
	
	private func amountChanged(row: DecimalRow) {
		guard let totalRow: DecimalRow = form.rowBy(tag: Row.Total.tag), let account = account else {
			return
		}
		
		if let amount = row.value {
			totalAmount = amount + defaultFee
			totalRow.evaluateDisabled()
		} else {
			totalAmount = nil
		}
		
		totalRow.value = totalAmount
		totalRow.evaluateDisabled()
		
		if let totalAmount = totalAmount {
			let isValid = totalAmount > 0.0 && totalAmount < (Double(account.balance) * AdamantFormatters.currencyShift )
			sendButton.isEnabled = isValid
		} else {
			sendButton.isEnabled = false
		}
	}
	
	
	// MARK: - IBActions
	
	@IBAction func sendFunds(_ sender: Any) {
		guard let account = loginService.loggedAccount, let keypair = loginService.keypair else {
			return
		}
		
		guard let recipientRow = form.rowBy(tag: Row.Recipient.tag) as? TextRow,
			let recipient = recipientRow.value,
			AdamantFormatters.validateAdamantAddress(address: recipient),
			let totalRow = form.rowBy(tag: Row.Total.tag) as? DecimalRow,
			let amount = totalRow.value else {
			return
		}
		
		let alert = UIAlertController(title: "Send \(amount) \(AdamantFormatters.currencyCode) to \(recipient)?", message: "You can't undo this action.", preferredStyle: .alert)
		let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
		let sendAction = UIAlertAction(title: "Send", style: .default, handler: { _ in
			FTIndicator.showProgress(withMessage: "Processing transaction...", userInteractionEnable: false)
			
			// Check if address is valid
			self.apiService.getPublicKey(byAddress: recipient, completionHandler: { (key, error) in
				guard key != nil else {
					FTIndicator.showError(withMessage: "Account not found: \(recipient)")
					return
				}
				
				self.apiService.transferFunds(sender: account.address, recipient: recipient, amount: AdamantFormatters.from(double: amount), keypair: keypair, completionHandler: { [weak self] (success, error) in
					if success {
						FTIndicator.showSuccess(withMessage: "Funds sended!")
						// TODO: goto transactions scene
						self?.dismiss(animated: true, completion: nil)
					} else {
						FTIndicator.showError(withMessage: error?.message ?? "Failed. Try later.")
					}
				})
			})
		})
		
		alert.addAction(cancelAction)
		alert.addAction(sendAction)
		
		present(alert, animated: true, completion: nil)
	}
}
