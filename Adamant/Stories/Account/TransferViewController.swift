//
//  TransferViewController.swift
//  Adamant
//
//  Created by Anokhov Pavel on 09.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import Eureka

class TransferViewController: FormViewController {
	
	// MARK: - Rows
	
	private struct Row {
		static let Balance = Row("balance")
		static let Amount = Row("amount")
		static let MaxToTransfer = Row("max")
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
	var accountService: AccountService!
	var dialogService: DialogService!
	
	private(set) var maxToTransfer: Double = 0.0
	
	
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
			sendButton.isEnabled = maxToTransfer > 0.0
			let balance = Double(account.balance) * AdamantUtilities.currencyShift
			maxToTransfer = balance - defaultFee > 0 ? balance - defaultFee : 0.0
			
			form +++ Section("Your wallet")
			<<< DecimalRow() {
				$0.title = "Balance"
				$0.value = balance
				$0.tag = Row.Balance.tag
				$0.disabled = true
				$0.formatter = AdamantUtilities.currencyFormatter
			}
			<<< DecimalRow() {
				$0.title = "Max to transfer"
				$0.value = maxToTransfer
				$0.tag = Row.MaxToTransfer.tag
				$0.disabled = true
				$0.formatter = AdamantUtilities.currencyFormatter
			}
		} else {
			sendButton.isEnabled = false
		}
		
		// MARK: - Transfer section
		form +++ Section("transfer info")
		
		<<< TextRow() {
			$0.title = "Address"
			$0.placeholder = "of the recipient"
			$0.tag = Row.Recipient.tag
			$0.add(rule: RuleClosure<String>(closure: { value -> ValidationError? in
				if let value = value?.uppercased(),
					AdamantUtilities.validateAdamantAddress(address: value) {
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
			$0.formatter = AdamantUtilities.currencyFormatter
//			$0.add(rule: RuleSmallerOrEqualThan<Double>(max: maxToTransfer))
//			$0.validationOptions = .validatesOnChange
			}.onChange(amountChanged)
		<<< DecimalRow() {
			$0.title = "Transaction fee"
			$0.value = defaultFee
			$0.tag = Row.Fee.tag
			$0.disabled = true
			$0.formatter = AdamantUtilities.currencyFormatter
		}
		<<< DecimalRow() {
			$0.title = "Amount including fee"
			$0.value = nil
			$0.tag = Row.Total.tag
			$0.disabled = true
			$0.formatter = AdamantUtilities.currencyFormatter
		}
		<<< ButtonRow() {
			$0.title = "Send funds"
			$0.tag = Row.SendButton.tag
			$0.disabled = Condition.function([Row.Total.tag], { [weak self] form -> Bool in
				guard let row: DecimalRow = form.rowBy(tag: Row.Amount.tag),
					let amount = row.value,
					amount > 0,
					AdamantUtilities.validateAmount(amount: amount),
					let maxToTransfer = self?.maxToTransfer else {
					return true
				}

				return amount > maxToTransfer
			})
			}.onCellSelection({ [weak self] (cell, row) in
				self?.sendFunds(row)
			})
		
		
		// MARK: - UI
		navigationAccessoryView.tintColor = UIColor.adamantPrimary
		
		for row in form.allRows {
			row.baseCell?.textLabel?.font = UIFont.adamantPrimary(size: 17)
			row.baseCell?.textLabel?.textColor = UIColor.adamantPrimary
			row.baseCell?.tintColor = UIColor.adamantPrimary
			
			// TODO: Not working. Somehow font get's dropped at runtime.
			//				if let cell = row.baseCell as? TextFieldCell {
			//					cell.textField.font = font
			//					cell.textField.textColor = color
			//				}
		}
		
		let button: ButtonRow? = form.rowBy(tag: Row.SendButton.tag)
		button?.evaluateDisabled()
    }
	
	
	// MARK: - Form Events
	
	private func amountChanged(row: DecimalRow) {
		guard let totalRow: DecimalRow = form.rowBy(tag: Row.Total.tag), let account = account else {
			return
		}
		
		guard let amount = row.value else {
			totalAmount = nil
			sendButton.isEnabled = false
			row.cell.titleLabel?.textColor = .black
			return
		}
		
		totalAmount = amount + defaultFee
		totalRow.evaluateDisabled()
		
		totalRow.value = totalAmount
		totalRow.evaluateDisabled()
		
		if let totalAmount = totalAmount {
			if amount > 0, AdamantUtilities.validateAmount(amount: amount),
				totalAmount > 0.0 && totalAmount < (Double(account.balance) * AdamantUtilities.currencyShift) {
				sendButton.isEnabled = true
				row.cell.titleLabel?.textColor = .black
			} else {
				sendButton.isEnabled = false
				row.cell.titleLabel?.textColor = .red
			}
		} else {
			sendButton.isEnabled = false
			row.cell.titleLabel?.textColor = .black
		}
	}
	
	
	// MARK: - IBActions
	
	@IBAction func sendFunds(_ sender: Any) {
		guard let dialogService = self.dialogService, let apiService = self.apiService else {
			fatalError("Dependecies fatal error")
		}
		
		guard let account = accountService.account, let keypair = accountService.keypair else {
			return
		}
		
		guard let recipientRow = form.rowBy(tag: Row.Recipient.tag) as? TextRow,
			let recipient = recipientRow.value,
			let amountRow = form.rowBy(tag: Row.Amount.tag) as? DecimalRow,
			let amount = amountRow.value else {
			return
		}
		
		guard amount > 0, AdamantUtilities.validateAmount(amount: amount) else {
			dialogService.showError(withMessage: "You should send more money")
			return
		}
		
		guard AdamantUtilities.validateAdamantAddress(address: recipient) else {
			dialogService.showError(withMessage: "Enter valid recipient address")
			return
		}
		
		guard amount <= maxToTransfer else {
			dialogService.showError(withMessage: "You don't have that kind of money")
			return
		}
		
		let alert = UIAlertController(title: "Send \(amount) \(AdamantUtilities.currencyCode) to \(recipient)?", message: "You can't undo this action.", preferredStyle: .alert)
		let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
		let sendAction = UIAlertAction(title: "Send", style: .default, handler: { _ in
			dialogService.showProgress(withMessage: "Processing transaction...", userInteractionEnable: false)
			
			// Check if address is valid
			apiService.getPublicKey(byAddress: recipient, completionHandler: { (key, error) in
				guard key != nil else {
					dialogService.showError(withMessage: "Account not found: \(recipient)")
					return
				}
				
				apiService.transferFunds(sender: account.address, recipient: recipient, amount: AdamantUtilities.from(double: amount), keypair: keypair, completionHandler: { [weak self] (success, error) in
					
					DispatchQueue.main.async {
						if success {
							dialogService.showSuccess(withMessage: "Funds sended!")
							
							self?.accountService.updateAccountData()
							
							if let nav = self?.navigationController {
								nav.popViewController(animated: true)
							} else {
								self?.dismiss(animated: true, completion: nil)
							}
						} else {
							dialogService.showError(withMessage: error?.message ?? "Failed. Try later.")
						}
					}
				})
			})
		})
		
		alert.addAction(cancelAction)
		alert.addAction(sendAction)
		
		present(alert, animated: true, completion: nil)
	}
}
