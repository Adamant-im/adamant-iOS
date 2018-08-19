//
//  TransferViewControllerBase.swift
//  Adamant
//
//  Created by Anokhov Pavel on 09.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import Eureka
import web3swift
import BigInt

// MARK: - Transfer Delegate Protocol

protocol TransferViewControllerDelegate: class {
	func transferViewController(_ viewController: TransferViewControllerBase, didFinishWith data: String?)
}


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
        
        static let send = NSLocalizedString("TransferScene.Send", comment: "Transfer: Send button")
        
        static let cantUndo = NSLocalizedString("TransferScene.CantUndo", comment: "Transfer: Send button")
		
		private init() { }
	}
}

fileprivate extension String.adamantLocalized.alert {
	static let confirmSendMessageFormat = NSLocalizedString("TransferScene.SendConfirmFormat", comment: "Transfer: Confirm transfer %1$@ tokens to %2$@ message. Note two variables: at runtime %1$@ will be amount (with ADM suffix), and %2$@ will be recipient address. You can use address before amount with this so called 'position tokens'.")
	static let send = NSLocalizedString("TransferScene.Send", comment: "Transfer: Confirm transfer alert: Send tokens button")
}



// MARK: -
class TransferViewControllerBase: FormViewController {
	
	// MARK: - Rows
	
	enum BaseRows {
		case balance
		case amount
		case maxToTransfer
		case address
		case fee
		case total
        case comments
		case sendButton
		
		var tag: String {
			switch self {
			case .balance: return "balance"
			case .amount: return "amount"
			case .maxToTransfer: return "max"
			case .address: return "recipient"
			case .fee: return "fee"
			case .total: return "total"
            case .comments: return "comments"
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
            case .comments: return NSLocalizedString("TransferScene.Row.Comments", comment: "Transfer: transfer comment")
			case .sendButton: return String.adamantLocalized.transfer.send
			}
		}
	}
	
	enum Sections {
		case wallet
		case recipient
		case transferInfo
		
		var tag: String {
			switch self {
			case .wallet: return "wlt"
			case .recipient: return "rcp"
			case .transferInfo: return "trsfr"
			}
		}
		
		var localized: String {
			switch self {
			case .wallet: return NSLocalizedString("TransferScene.Section.YourWallet", comment: "Transfer: 'Your wallet' section")
				
			case .recipient: return "Получатель"
//				NSLocalizedString("TransferScene.Section.Recipient", comment: "Transfer: 'Recipient info' section")
				
				
			case .transferInfo: return NSLocalizedString("TransferScene.Section.TransferInfo", comment: "Transfer: 'Transfer info' section")
			}
		}
	}
	
	
	// MARK: - Dependencies
	
	var dialogService: DialogService!
	
	
	// MARK: - Properties
	
	var service: WalletServiceWithSend?
	weak var delegate: TransferViewControllerDelegate?
	
	var recipient: String? = nil
	var amount: Decimal? = nil
	
	var maxToTransfer: Decimal {
		guard let service = service, let balance = service.wallet?.balance else {
			return 0
		}
		
		let max = balance - service.transactionFee
		
		if max >= 0 {
			return max
		} else {
			return 0
		}
	}
	
	// MARK: - Lifecycle
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		// MARK: - UI
		navigationAccessoryView.tintColor = UIColor.adamantPrimary
		
		// MARK: - Sections
		form.append(walletSection())
		form.append(contentsOf: customSections())
		
        // MARK: - Transfer section
		form +++ Section()
		<<< ButtonRow() { [weak self] in
			$0.title = BaseRows.sendButton.localized
			$0.tag = BaseRows.sendButton.tag
			
			$0.disabled = Condition.function([BaseRows.address.tag, BaseRows.amount.tag]) { [weak self] form -> Bool in
				guard let service = self?.service, let wallet = service.wallet, wallet.balance > service.transactionFee else {
					return true
				}
				
				guard let isValid = self?.formIsValid() else {
					return true
				}
				
				return !isValid
			}
		}.onCellSelection { [weak self] (cell, row) in
			self?.confirmSendFunds()
		}
    }
	
	// MARK: - Form constructors
	
	func walletSection() -> Section {
		let section = Section(Sections.wallet.localized) {
			$0.tag = Sections.wallet.tag
		}
		
		// MARK: Balance
		<<< DecimalRow() { [weak self] in
			$0.title = BaseRows.balance.localized
			$0.tag = BaseRows.balance.tag
			$0.disabled = true
			$0.formatter = self?.balanceFormatter
			
			if let wallet = self?.service?.wallet {
				$0.value = wallet.balance.doubleValue
			} else {
				$0.value = 0
			}
		}
			
		// MARK: Max to transfer
		<<< DecimalRow() { [weak self] in
			$0.title = BaseRows.maxToTransfer.localized
			$0.tag = BaseRows.maxToTransfer.tag
			$0.disabled = true
			$0.formatter = AdamantUtilities.currencyFormatter
			
			if let maxToTransfer = self?.maxToTransfer {
				$0.value = maxToTransfer.doubleValue
			}
		}
		
		return section
	}
	
	
	
    /*
    private func createETHForm() {
        if let ethAccount = ethApiService.account, let ethBalanceBigInt = ethAccount.balance, let ethBalanceString = Web3.Utils.formatToEthereumUnits(ethBalanceBigInt), let ethBalance = Double(ethBalanceString) {
            
            maxToTransfer = ethBalance
            
            if let feeString = Web3.Utils.formatToEthereumUnits(BigUInt(AdamantEthApiService.defaultGasPrice * AdamantEthApiService.transferGas), toUnits: .eth, decimals: 8), let fee = Double(feeString) {
//                defaultFee = fee
            }
            
            let currencyFormatter = NumberFormatter()
            currencyFormatter.numberStyle = .decimal
            currencyFormatter.roundingMode = .floor
            currencyFormatter.positiveFormat = "#.######## ETH"
            
            form +++ Section(Sections.wallet.localized)
                <<< DecimalRow() {
                    $0.title = Row.balance.localized
                    $0.value = ethBalance
                    $0.tag = Row.balance.tag
                    $0.disabled = true
                    $0.formatter = currencyFormatter
                }
            
            // MARK: - Transfer section
            form +++ Section(Sections.transferInfo.localized)
                
                <<< TextRow() {
                    $0.title = Row.address.localized
                    $0.placeholder = String.adamantLocalized.transfer.addressPlaceholder
                    $0.tag = Row.address.tag
//                    $0.value = toAddress
                    $0.add(rule: RuleClosure<String>(closure: { value -> ValidationError? in
                        guard let value = value?.lowercased() else {
                            return ValidationError(msg: String.adamantLocalized.transfer.addressValidationError)
                        }
                        
                        if let walletAddress = EthereumAddress(value) {
                            if walletAddress.isValid {
                                return nil
                            } else {
                                return ValidationError(msg: String.adamantLocalized.transfer.addressValidationError)
                            }
                        } else {
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
                    $0.formatter = currencyFormatter
                    $0.add(rule: RuleSmallerOrEqualThan<Double>(max: maxToTransfer))
                    $0.validationOptions = .validatesOnChange
                    }.onChange(ethAmountChanged)
                <<< DecimalRow() {
                    $0.title = Row.fee.localized
//                    $0.value = defaultFee
                    $0.tag = Row.fee.tag
                    $0.disabled = true
                    $0.formatter = currencyFormatter
                }
                <<< DecimalRow() {
                    $0.title = Row.total.localized
                    $0.value = nil
                    $0.tag = Row.total.tag
                    $0.disabled = true
                    $0.formatter = currencyFormatter
            }
        }
    }
*/

/*
    private func createLSKForm() {
        if let account = lskApiService.account, let balanceString = account.balanceString, let balance = Double(balanceString) {
            
            maxToTransfer = balance
//            defaultFee = AdamantLskApiService.defaultFee
			
            let currencyFormatter = NumberFormatter()
            currencyFormatter.numberStyle = .decimal
            currencyFormatter.roundingMode = .floor
            currencyFormatter.positiveFormat = "#.######## LSK"
            
            form +++ Section(Sections.wallet.localized)
                <<< DecimalRow() {
                    $0.title = Row.balance.localized
                    $0.value = balance
                    $0.tag = Row.balance.tag
                    $0.disabled = true
                    $0.formatter = currencyFormatter
            }
            
            // MARK: - Transfer section
            form +++ Section(Sections.transferInfo.localized)
                
                <<< TextRow() {
                    $0.title = Row.address.localized
                    $0.placeholder = String.adamantLocalized.transfer.addressPlaceholder
                    $0.tag = Row.address.tag
//                    $0.value = toAddress
                    $0.add(rule: RuleClosure<String>(closure: { value -> ValidationError? in
                        guard let value = value?.uppercased() else {
                            return ValidationError(msg: String.adamantLocalized.transfer.addressValidationError)
                        }
                        switch AdamantLskApiService.validateAddress(address: value) {
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
                    $0.formatter = currencyFormatter
                    $0.add(rule: RuleSmallerOrEqualThan<Double>(max: maxToTransfer))
                    $0.validationOptions = .validatesOnChange
                    }.onChange(ethAmountChanged)
                <<< DecimalRow() {
                    $0.title = Row.fee.localized
//                    $0.value = defaultFee
                    $0.tag = Row.fee.tag
                    $0.disabled = true
                    $0.formatter = currencyFormatter
                }
                <<< DecimalRow() {
                    $0.title = Row.total.localized
                    $0.value = nil
                    $0.tag = Row.total.tag
                    $0.disabled = true
                    $0.formatter = currencyFormatter
            }
        }
    }
*/

	// MARK: - Tools
	
	func validateForm() {
		guard let service = service, let wallet = service.wallet else {
			return
		}
		
		if let row: DecimalRow = form.rowBy(tag: BaseRows.maxToTransfer.tag) {
			markRow(row, valid: wallet.balance > service.transactionFee)
		}
		
		if let row: TextRow = form.rowBy(tag: BaseRows.address.tag) {
			if let address = row.value, validateRecipient(address) {
				recipient = address
				markRow(row, valid: true)
			} else {
				recipient = nil
				markRow(row, valid: false)
			}
		} else {
			recipient = nil
		}
		
		if let row: DecimalRow = form.rowBy(tag: BaseRows.amount.tag) {
			if let raw = row.value {
				let amount = Decimal(raw)
				self.amount = amount
				
				markRow(row, valid: validateAmount(amount))
			} else {
				amount = nil
				markRow(row, valid: true)
			}
		} else {
			amount = nil
		}
		
		if let row: DecimalRow = form.rowBy(tag: BaseRows.total.tag) {
			if let amount = amount {
				row.value = (amount + service.transactionFee).doubleValue
				row.updateCell()
				markRow(row, valid: validateAmount(amount))
			} else {
				row.value = nil
				markRow(row, valid: true)
				row.updateCell()
			}
		}
		
		if let row: ButtonRow = form.rowBy(tag: BaseRows.sendButton.tag) {
			row.evaluateDisabled()
		}
	}
	
	func markRow(_ row: BaseRowType, valid: Bool) {
		row.baseCell.textLabel?.textColor = valid ? UIColor.black : UIColor.red
	}
	
	
	/*
    private func ethAmountChanged(row: DecimalRow) {
        guard let totalRow: DecimalRow = form.rowBy(tag: Row.total.tag), let sendButton: ButtonRow = form.rowBy(tag: Row.sendButton.tag) else {
            return
        }
        
        guard let amount = row.value else {
            totalAmount = nil
            sendButton.disabled = true
            sendButton.evaluateDisabled()
            row.cell.titleLabel?.textColor = .black
            return
        }
        
//        totalAmount = amount + defaultFee
        totalRow.evaluateDisabled()
        
        totalRow.value = totalAmount
        totalRow.evaluateDisabled()
        
        if let totalAmount = totalAmount {
            if amount > 0, totalAmount > 0.0 && totalAmount < maxToTransfer {
                sendButton.disabled = false
                row.cell.titleLabel?.textColor = .black
            } else {
                sendButton.disabled = true
                row.cell.titleLabel?.textColor = .red
            }
        } else {
            sendButton.disabled = true
            row.cell.titleLabel?.textColor = .black
        }
        sendButton.evaluateDisabled()
    }
	*/
	
	
	// MARK: - Abstract
	
	func customSections() -> [Section] {
		fatalError()
	}
	
	/// Override this to provide custom balance formatter
	var balanceFormatter: NumberFormatter {
		return AdamantBalanceFormat.full.defaultFormatter
	}
	
	/// Override this to provide custom validation logic
	/// Default - positive number, amount + fee less than or equal to wallet balance
	func validateAmount(_ amount: Decimal, withFee: Bool = true) -> Bool {
		guard amount > 0 else {
			return false
		}
		
		guard let service = service, let balance = service.wallet?.balance else {
			return false
		}
		
		let total = withFee ? amount + service.transactionFee : amount
		
		return balance > total
	}
	
	
	/// You must implement validation logic
	func validateRecipient(_ address: String) -> Bool {
		fatalError()
	}
	
	func formIsValid() -> Bool {
		if let recipient = recipient, validateRecipient(recipient), let amount = amount, validateAmount(amount) {
			return true
		} else {
			return false
		}
	}
	
	func sendFunds() {
		fatalError("You must implement send logic")
	}
	
	// MARK: - Send Actions
	private func confirmSendFunds() {
		guard let recipient = recipient, let amount = amount else {
			return
		}
		
		guard validateRecipient(recipient) else {
			dialogService.showWarning(withMessage: String.adamantLocalized.transfer.addressValidationError)
			return
		}
		
		guard amount <= maxToTransfer else {
			dialogService.showWarning(withMessage: String.adamantLocalized.transfer.amountTooHigh)
			return
		}
		
		let alert = UIAlertController(title: String.localizedStringWithFormat(String.adamantLocalized.alert.confirmSendMessageFormat, "\(amount) \(AdamantUtilities.currencyCode)", recipient), message: String.adamantLocalized.transfer.cantUndo, preferredStyle: .alert)
		let cancelAction = UIAlertAction(title: String.adamantLocalized.alert.cancel , style: .cancel, handler: nil)
		let sendAction = UIAlertAction(title: String.adamantLocalized.alert.send, style: .default) { [weak self] _ in
			self?.sendFunds()
		}
		
		alert.addAction(cancelAction)
		alert.addAction(sendAction)
		
		present(alert, animated: true, completion: nil)
	}
	
	
	/*
    func sendETHFunds() {
        guard let recipientRow = form.rowBy(tag: Row.address.tag) as? TextRow,
            let recipient = recipientRow.value,
            let amountRow = form.rowBy(tag: Row.amount.tag) as? DecimalRow,
            let amount = amountRow.value else {
                return
        }
        
        guard recipientRow.isValid else {
            dialogService.showWarning(withMessage: (recipientRow.validationErrors.first?.msg) ?? "Invalid Address")
            return
        }
        
        guard let totalAmount = totalAmount, totalAmount <= maxToTransfer else {
            dialogService.showWarning(withMessage: String.adamantLocalized.transfer.amountTooHigh)
            return
        }
        
        let alert = UIAlertController(title: String.localizedStringWithFormat(String.adamantLocalized.alert.confirmSendMessageFormat, "\(amount) ETH", recipient), message: String.adamantLocalized.transfer.cantUndo, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: String.adamantLocalized.alert.cancel , style: .cancel, handler: nil)
        let sendAction = UIAlertAction(title: String.adamantLocalized.alert.send, style: .default, handler: { _ in
            self.sendEth(to: recipient, amount: amount)
        })
        
        alert.addAction(cancelAction)
        alert.addAction(sendAction)
        
        present(alert, animated: true, completion: nil)
    }
*/
	
	/*
    func sendLSKFunds() {
        guard let recipientRow = form.rowBy(tag: Row.address.tag) as? TextRow,
            let recipient = recipientRow.value,
            let amountRow = form.rowBy(tag: Row.amount.tag) as? DecimalRow,
            let amount = amountRow.value else {
                return
        }
        
        guard recipientRow.isValid else {
            dialogService.showWarning(withMessage: (recipientRow.validationErrors.first?.msg) ?? "Invalid Address")
            return
        }
        
        guard let totalAmount = totalAmount, totalAmount <= maxToTransfer else {
            dialogService.showWarning(withMessage: String.adamantLocalized.transfer.amountTooHigh)
            return
        }
        
        let alert = UIAlertController(title: String.localizedStringWithFormat(String.adamantLocalized.alert.confirmSendMessageFormat, "\(amount) LSK", recipient), message: String.adamantLocalized.transfer.cantUndo, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: String.adamantLocalized.alert.cancel , style: .cancel, handler: nil)
        let sendAction = UIAlertAction(title: String.adamantLocalized.alert.send, style: .default, handler: { _ in
            self.sendLsk(to: recipient, amount: amount)
        })
        
        alert.addAction(cancelAction)
        alert.addAction(sendAction)
        
        present(alert, animated: true, completion: nil)
    }
*/
    
    // MARK: - Private
	/*
    private func sendEth(to recipient: String, amount: Double) {
        self.dialogService.showProgress(withMessage: String.adamantLocalized.transfer.transferProcessingMessage, userInteractionEnable: false)
        
        self.ethApiService.createTransaction(toAddress: recipient, amount: amount) { (result) in
            switch result {
            case .success(let transaction):
                self.ethApiService.sendTransaction(transaction: transaction, completion: { (result) in
                    switch result {
                    case .success(let txHash):
                        DispatchQueue.global().async {
                            print("TxHash: \(txHash)")
                            
                            var message = ["type": "eth_transaction", "amount": "\(amount)", "hash": txHash, "comments":""]
                            
                            if let commentsRow = self.form.rowBy(tag: Row.comments.tag) as? TextAreaRow,
                                let comments = commentsRow.value {
                                message["comments"] = comments
                            }
                            
                            do {
                                let data = try JSONEncoder().encode(message)
                                guard let raw = String(data: data, encoding: String.Encoding.utf8) else {
                                    return
                                }
                                
                                print("Payload: \(raw)")
                                DispatchQueue.main.async {
                                    self.delegate?.transferFinished(with: raw)
                                    self.dialogService.showSuccess(withMessage: String.adamantLocalized.transfer.transferSuccess)
                                    self.close()
                                }
                            } catch {
                                DispatchQueue.main.async {
                                    self.dialogService.showError(withMessage: "ETH Wallet: Send - wrong data issue", error: nil)
                                }
                            }
                        }
                        
                        break
                    case .failure(let error):
                        self.dialogService.showError(withMessage: "Transrer issue", error: error)
                        break
                    }
                })
                break
            case .failure(let error):
                self.dialogService.showError(withMessage: "Transrer issue", error: error)
                break
            }
        }
    }
    
    private func sendLsk(to recipient: String, amount: Double) {
        self.dialogService.showProgress(withMessage: String.adamantLocalized.transfer.transferProcessingMessage, userInteractionEnable: false)
        
        self.lskApiService.createTransaction(toAddress: recipient, amount: amount) { (result) in
            switch result {
            case .success(let transaction):
                if let id = transaction.id {
                    var message = ["type": "lsk_transaction", "amount": "\(amount)", "hash": id, "comments":""]
                    
                    if let commentsRow = self.form.rowBy(tag: Row.comments.tag) as? TextAreaRow,
                        let comments = commentsRow.value {
                        message["comments"] = comments
                    }
                    
                    do {
                        let data = try JSONEncoder().encode(message)
                        guard let raw = String(data: data, encoding: String.Encoding.utf8) else {
                            return
                        }
                        print("Payload: \(raw)")
                        self.delegate?.transferFinished(with: raw)
                        
                        self.lskApiService.sendTransaction(transaction: transaction, completion: { (result) in
                            switch result {
                            case .success(let hash):
                                print("Hash: \(hash)")
                                self.dialogService.showSuccess(withMessage: String.adamantLocalized.transfer.transferSuccess)
                                self.close()
                            case .failure(let error):
                                self.dialogService.showError(withMessage: "Transrer issue", error: error)
                            }
                        })
                    } catch {
                        self.dialogService.showError(withMessage: "Transrer issue", error: nil)
                    }
                } else {
                    self.dialogService.showError(withMessage: "Transrer issue", error: nil)
                }
                
                break
            case .failure(let error):
                self.dialogService.showError(withMessage: "Transrer issue", error: error)
                break
            }
        }
    }
*/
}
