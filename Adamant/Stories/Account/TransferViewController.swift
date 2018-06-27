//
//  TransferViewController.swift
//  Adamant
//
//  Created by Anokhov Pavel on 09.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import Eureka
import web3swift
import BigInt

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

// MARK: Transfer Delegate Protocol

protocol TransferDelegate {
    func transferFinished(with data:String)
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
			case .sendButton: return String.adamantLocalized.transfer.send
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
    
    enum Token {
        case ADM
        case ETH
    }
	
	
	// MARK: - Dependencies
	
	var apiService: ApiService!
	var accountService: AccountService!
	var dialogService: DialogService!
    var ethApiService: EthApiServiceProtocol!
	
	private(set) var maxToTransfer: Double = 0.0
	
	
	// MARK: - Properties
	
	var defaultFee = 0.5
	var account: Account?
	
    var token: Token = .ADM
    var toAddress: String = ""
    
	private(set) var totalAmount: Double? = nil
    
    var delegate: TransferDelegate?

	
	// MARK: - Lifecycle
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
        switch token {
        case .ADM:
            createADMForm()
        case .ETH:
            createETHForm()
        }
		
        // MARK: - Transfer section
        form +++ Section()
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
		navigationAccessoryView.tintColor = UIColor.adamantPrimary
		
		let button: ButtonRow? = form.rowBy(tag: Row.sendButton.tag)
        button?.disabled = true
        button?.evaluateDisabled()
    }
	
    // MARK: - Form constructors
    
    private func createADMForm() {
        // MARK: - Wallet section
        if let account = accountService.account {
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
                $0.value = toAddress
                $0.validationOptions = .validatesOnBlur
                }.cellUpdate({ (cell, row) in
                    cell.titleLabel?.textColor = row.isValid ? .black : .red
                })
            <<< DecimalRow() {
                $0.title = Row.amount.localized
                $0.placeholder = String.adamantLocalized.transfer.amountPlaceholder
                $0.tag = Row.amount.tag
                $0.formatter = AdamantUtilities.currencyFormatter
                //            $0.add(rule: RuleSmallerOrEqualThan<Double>(max: maxToTransfer))
                //            $0.validationOptions = .validatesOnChange
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
    }
    
    private func createETHForm() {
        // MARK: - Wallet section
        if let ethAccount = ethApiService.account, let ethBalanceBigInt = ethAccount.balance, let ethBalanceString = Web3.Utils.formatToEthereumUnits(ethBalanceBigInt), let ethBalance = Double(ethBalanceString) {
            
            maxToTransfer = ethBalance
            
            if let feeString = Web3.Utils.formatToEthereumUnits(BigUInt(EthApiService.defaultGasPrice * EthApiService.transferGas), toUnits: .eth, decimals: 8), let fee = Double(feeString) {
                defaultFee = fee
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
                    $0.value = toAddress
                    
                    // TODO: Validation for ETH address
//                    $0.add(rule: RuleClosure<String>(closure: { value -> ValidationError? in
//                        guard let value = value?.uppercased() else {
//                            return ValidationError(msg: String.adamantLocalized.transfer.addressValidationError)
//                        }
//
//                        switch AdamantUtilities.validateAdamantAddress(address: value) {
//                        case .valid:
//                            return nil
//
//                        case .system, .invalid:
//                            return ValidationError(msg: String.adamantLocalized.transfer.addressValidationError)
//                        }
//                    }))
//                    $0.validationOptions = .validatesOnBlur
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
                    $0.value = defaultFee
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
	
	// MARK: - Form Events
	
	private func amountChanged(row: DecimalRow) {
		guard let totalRow: DecimalRow = form.rowBy(tag: Row.total.tag), let sendButton: ButtonRow = form.rowBy(tag: Row.sendButton.tag), let account = accountService.account else {
			return
		}
		
		guard let amount = row.value else {
			totalAmount = nil
            sendButton.disabled = true
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
	}
    
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
        
        totalAmount = amount + defaultFee
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
	
	
	// MARK: - Send Actions
	
    func sendFunds(_ sender: Any) {
        switch token {
        case .ADM:
            sendADMFunds()
        case .ETH:
            sendETHFunds()
        }
    }
    
    func sendADMFunds() {
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
		
		let alert = UIAlertController(title: String.localizedStringWithFormat(String.adamantLocalized.alert.confirmSendMessageFormat, "\(amount) \(AdamantUtilities.currencyCode)", recipient), message: String.adamantLocalized.transfer.cantUndo, preferredStyle: .alert)
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
								
								self?.close()
							}
							
						case .failure(let error):
							dialogService.showError(withMessage: error.localized, error: error)
						}
						
					}
					
					
				case .failure(let error):
					dialogService.showError(withMessage: String.adamantLocalized.transfer.accountNotFound, error: error)
				}
			}
		})
		
		alert.addAction(cancelAction)
		alert.addAction(sendAction)
		
		present(alert, animated: true, completion: nil)
	}
    
    func sendETHFunds() {
        guard let recipientRow = form.rowBy(tag: Row.address.tag) as? TextRow,
            let recipient = recipientRow.value,
            let amountRow = form.rowBy(tag: Row.amount.tag) as? DecimalRow,
            let amount = amountRow.value else {
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
    
    private func sendEth(to recipient: String, amount: Double) {
        self.dialogService.showProgress(withMessage: String.adamantLocalized.transfer.transferProcessingMessage, userInteractionEnable: false)
        
        self.ethApiService.sendFunds(toAddress: recipient, amount: amount) { (result) in
            switch result {
            case .success(let value):
                print("Payload: \(value)")
                
                self.delegate?.transferFinished(with: value)
                self.dialogService.showSuccess(withMessage: String.adamantLocalized.transfer.transferSuccess)
                self.close()
            
            case .failure(let error):
                self.dialogService.showError(withMessage: "Transrer issue", error: error)
            }
        }
    }
    
    private func close() {
        if let nav = self.navigationController {
            nav.popViewController(animated: true)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
}
