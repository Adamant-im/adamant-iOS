//
//  TransferViewController.swift
//  Adamant-ios
//
//  Created by Anokhov Pavel on 09.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import Eureka

class TransferViewController: FormViewController {
	private struct Row {
		static let Amount = Row("amount")
		static let Fee = Row("fee")
		static let Total = Row("total")
		static let SendButton = Row("send")
		
		let tag: String
		private init(_ tag: String) {
			self.tag = tag
		}
	}
	
	
	// MAKR: - Properties
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
		
		<<< TextRow() { r in
			r.title = "Address"
			r.placeholder = "of the reciever"
//			r.add(rule: RuleClosure<String>(closure: { value -> ValidationError? in
//				
//			}))
		}
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
		
		if let font = UIFont(name: "Exo 2", size: 17),
			let color = UIColor(named: "Gray_main") {
			navigationAccessoryView.tintColor = color

			for row in form.allRows {
				row.baseCell?.textLabel?.font = font
				row.baseCell?.textLabel?.textColor = color
				row.baseCell?.tintColor = color
				
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
	}
}
