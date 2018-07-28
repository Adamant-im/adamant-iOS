//
//  TransferViewController.swift
//  Adamant
//
//  Created by Anokhov Pavel on 09.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import Eureka


// MARK: - Localization
extension String.adamantLocalized {
	struct transfer {
		static let addressPlaceholder = NSLocalizedString("TransferScene.Recipient.Placeholder", comment: "Transfer: recipient address placeholder")
		static let amountPlaceholder = NSLocalizedString("TransferScene.Amount.Placeholder", comment: "Transfer: transfer amount placeholder")
		
		static let addressValidationError = NSLocalizedString("TransferScene.Error.InvalidAddress", comment: "Transfer: Address validation error")
		static let amountZeroError = NSLocalizedString("TransferScene.Error.TooLittleMoney", comment: "Transfer: Amount is zero, or even negative notification")
		static let amountTooHigh = NSLocalizedString("TransferScene.Error.NotEnoughtMoney", comment: "Transfer: Amount is hiegher that user's total money notification")
		static let accountNotFound = NSLocalizedString("TransferScene.Error.AddressNotFound", comment: "Transfer: Address not found error")
		
		static let transferProcessingMessage = NSLocalizedString("TransferScene.SendingFundsProgress", comment: "Transfer: Processing message")
		static let transferSuccess = NSLocalizedString("TransferScene.TransferSuccessMessage", comment: "Transfer: Tokens transfered successfully message")
		
		private init() { }
	}
}

fileprivate extension String.adamantLocalized.alert {
	static let confirmSendMessageFormat = NSLocalizedString("TransferScene.SendConfirmFormat", comment: "Transfer: Confirm transfer %1$@ tokens to %2$@ message. Note two variables: at runtime %1$@ will be amount (with ADM suffix), and %2$@ will be recipient address. You can use address before amount with this so called 'position tokens'.")
	static let send = NSLocalizedString("TransferScene.Send", comment: "Transfer: Confirm transfer alert: Send tokens button")
}


// MARK: -
class TransferViewController: FormViewController {
	
	// MARK: - Rows
	
	private enum Row {
		case balance
		case amount
		case maxToTransfer
		case address
		case fee
		case total
		case sendButton
		
		var tag: String {
			switch self {
			case .balance: return "balance"
			case .amount: return "amount"
			case .maxToTransfer: return "max"
			case .address: return "recipient"
			case .fee: return "fee"
			case .total: return "total"
			case .sendButton: return "send"
			}
		}
		
		var localized: String {
			switch self {
			case .balance: return NSLocalizedString("TransferScene.Row.Balance", comment: "Transfer: logged user balance.")
			case .amount: return NSLocalizedString("TransferScene.Row.Amount", comment: "Transfer: amount of adamant to transfer.")
			case .maxToTransfer: return NSLocalizedString("TransferScene.Row.MaxToTransfer", comment: "Transfer: maximum amount to transfer: available account money substracting transfer fee.")
			case .address: return NSLocalizedString("TransferScene.Row.Recipient", comment: "Transfer: recipient address")
			case .fee: return NSLocalizedString("TransferScene.Row.TransactionFee", comment: "Transfer: transfer fee")
			case .total: return NSLocalizedString("TransferScene.Row.Total", comment: "Transfer: total amount of transaction: money to transfer adding fee")
			case .sendButton: return NSLocalizedString("TransferScene.Row.Send", comment: "Transfer: Send button")
			}
		}
	}
	
	private enum Sections {
		case wallet
		case transferInfo
		
		var localized: String {
			switch self {
			case .wallet: return NSLocalizedString("TransferScene.Section.YourWallet", comment: "Transfer: 'Your wallet' section")
			case .transferInfo: return NSLocalizedString("TransferScene.Section.TransferInfo", comment: "Transfer: 'Transfer info' section")
			}
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
			let balance = (account.balance as NSDecimalNumber).doubleValue
			maxToTransfer = balance - defaultFee > 0 ? balance - defaultFee : 0.0
			
			form +++ Section(Sections.wallet.localized)
			<<< DecimalRow() {
				$0.title = Row.balance.localized
				$0.value = balance
				$0.tag = Row.balance.tag
				$0.disabled = true
				$0.formatter = AdamantUtilities.currencyFormatter
			}
			<<< DecimalRow() {
				$0.title = Row.maxToTransfer.localized
				$0.value = maxToTransfer
				$0.tag = Row.maxToTransfer.tag
				$0.disabled = true
				$0.formatter = AdamantUtilities.currencyFormatter
			}
		} else {
			sendButton.isEnabled = false
		}
		
		// MARK: - Transfer section
		form +++ Section(Sections.transferInfo.localized)
		
		<<< TextRow() {
			$0.title = Row.address.localized
			$0.placeholder = String.adamantLocalized.transfer.addressPlaceholder
			$0.tag = Row.address.tag
			$0.add(rule: RuleClosure<String>(closure: { value -> ValidationError? in
				guard let value = value?.uppercased() else {
					return ValidationError(msg: String.adamantLocalized.transfer.addressValidationError)
				}
				
				switch AdamantUtilities.validateAdamantAddress(address: value) {
				case .valid:
					return nil
					
				case .system, .invalid:
					return ValidationError(msg: String.adamantLocalized.transfer.addressValidationError)
				}
			}))
			$0.validationOptions = .validatesOnBlur
		}.cellUpdate({ (cell, row) in
			cell.titleLabel?.textColor = row.isValid ? .black : .red
		})
		<<< DecimalRow() {
			$0.title = Row.amount.localized
			$0.placeholder = String.adamantLocalized.transfer.amountPlaceholder
			$0.tag = Row.amount.tag
			$0.formatter = AdamantUtilities.currencyFormatter
//			$0.add(rule: RuleSmallerOrEqualThan<Double>(max: maxToTransfer))
//			$0.validationOptions = .validatesOnChange
			}.onChange(amountChanged)
		<<< DecimalRow() {
			$0.title = Row.fee.localized
			$0.value = defaultFee
			$0.tag = Row.fee.tag
			$0.disabled = true
			$0.formatter = AdamantUtilities.currencyFormatter
		}
		<<< DecimalRow() {
			$0.title = Row.total.localized
			$0.value = nil
			$0.tag = Row.total.tag
			$0.disabled = true
			$0.formatter = AdamantUtilities.currencyFormatter
		}
		<<< ButtonRow() {
			$0.title = Row.sendButton.localized
			$0.tag = Row.sendButton.tag
			$0.disabled = Condition.function([Row.total.tag], { [weak self] form -> Bool in
				guard let row: DecimalRow = form.rowBy(tag: Row.amount.tag),
					let amount = row.value,
					amount > 0,
					AdamantUtilities.validateAmount(amount: Decimal(amount)),
					let maxToTransfer = self?.maxToTransfer else {
					return true
				}

				return amount > maxToTransfer
			})
			}.onCellSelection({ [weak self] (cell, row) in
				self?.sendFunds(row)
			})
		
		
		// MARK: - UI
		navigationAccessoryView.tintColor = UIColor.adamant.primary
		
		let button: ButtonRow? = form.rowBy(tag: Row.sendButton.tag)
		button?.evaluateDisabled()
    }
	
	
	// MARK: - Form Events
	
	private func amountChanged(row: DecimalRow) {
		guard let totalRow: DecimalRow = form.rowBy(tag: Row.total.tag), let account = account else {
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
			if amount > 0, AdamantUtilities.validateAmount(amount: Decimal(amount)),
				totalAmount > 0.0 && totalAmount < (account.balance as NSDecimalNumber).doubleValue {
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
		
		guard let recipientRow = form.rowBy(tag: Row.address.tag) as? TextRow,
			let recipient = recipientRow.value,
			let amountRow = form.rowBy(tag: Row.amount.tag) as? DecimalRow,
			let raw = amountRow.value else {
			return
		}
		
		let amount = Decimal(raw)
		
		guard AdamantUtilities.validateAmount(amount: amount) else {
			dialogService.showWarning(withMessage: String.adamantLocalized.transfer.amountZeroError)
			return
		}
		
		switch AdamantUtilities.validateAdamantAddress(address: recipient) {
		case .valid:
			break
			
		case .system, .invalid:
			dialogService.showWarning(withMessage: String.adamantLocalized.transfer.addressValidationError)
			return
		}
		
		guard amount <= Decimal(maxToTransfer) else {
			dialogService.showWarning(withMessage: String.adamantLocalized.transfer.amountTooHigh)
			return
		}
		
		let alert = UIAlertController(title: String.localizedStringWithFormat(String.adamantLocalized.alert.confirmSendMessageFormat, "\(amount) \(AdamantUtilities.currencyCode)", recipient), message: "You can't undo this action.", preferredStyle: .alert)
		let cancelAction = UIAlertAction(title: String.adamantLocalized.alert.cancel , style: .cancel, handler: nil)
		let sendAction = UIAlertAction(title: String.adamantLocalized.alert.send, style: .default, handler: { _ in
			dialogService.showProgress(withMessage: String.adamantLocalized.transfer.transferProcessingMessage, userInteractionEnable: false)
			
			// Check if address is valid
			apiService.getPublicKey(byAddress: recipient) { result in
				switch result {
				case .success(_):
					apiService.transferFunds(sender: account.address, recipient: recipient, amount: amount, keypair: keypair) { [weak self] result in
						switch result {
						case .success(_):
							DispatchQueue.main.async {
								dialogService.showSuccess(withMessage: String.adamantLocalized.transfer.transferSuccess)
								
								self?.accountService.update()
								
								if let nav = self?.navigationController {
									nav.popViewController(animated: true)
								} else {
									self?.dismiss(animated: true, completion: nil)
								}
							}
							
						case .failure(let error):
							dialogService.showRichError(error: error)
						}
						
					}
					
					
				case .failure(let error):
					dialogService.showRichError(error: error)
				}
			}
		})
		
		alert.addAction(cancelAction)
		alert.addAction(sendAction)
		
		present(alert, animated: true, completion: nil)
	}
}
