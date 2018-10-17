//
//  TransferViewControllerBase.swift
//  Adamant
//
//  Created by Anokhov Pavel on 09.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import Eureka
import QRCodeReader


// MARK: - Transfer Delegate Protocol

protocol TransferViewControllerDelegate: class {
	func transferViewControllerDidFinishTransfer(_ viewController: TransferViewControllerBase)
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
		
        static let useMaxToTransfer = NSLocalizedString("TransferScene.UseMaxToTransfer", comment: "Tranfser: Confirm using maximum available for transfer tokens as amount to transfer.")
        
		private init() { }
	}
}

fileprivate extension String.adamantLocalized.alert {
	static let confirmSendMessageFormat = NSLocalizedString("TransferScene.SendConfirmFormat", comment: "Transfer: Confirm transfer %1$@ tokens to %2$@ message. Note two variables: at runtime %1$@ will be amount (with ADM suffix), and %2$@ will be recipient address. You can use address before amount with this so called 'position tokens'.")
	static func confirmSendMessage(formattedAmount amount: String, recipient: String) -> String {
		return String.localizedStringWithFormat(String.adamantLocalized.alert.confirmSendMessageFormat, "\(amount)", recipient)
	}
	static let send = NSLocalizedString("TransferScene.Send", comment: "Transfer: Confirm transfer alert: Send tokens button")
}



// MARK: -
class TransferViewControllerBase: FormViewController {
	
	// MARK: - Rows
	
	enum BaseRows {
		case balance
		case amount
		case maxToTransfer
        case name
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
            case .name: return "name"
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
			case .maxToTransfer: return NSLocalizedString("TransferScene.Row.MaxToTransfer", comment: "Transfer: maximum amount to transfer: available account money substracting transfer fee")
            case .name: return NSLocalizedString("TransferScene.Row.RecipientName", comment: "Transfer: recipient name")
			case .address: return NSLocalizedString("TransferScene.Row.RecipientAddress", comment: "Transfer: recipient address")
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
				
			case .recipient: return NSLocalizedString("TransferScene.Section.Recipient", comment: "Transfer: 'Recipient info' section")
				
			case .transferInfo: return NSLocalizedString("TransferScene.Section.TransferInfo", comment: "Transfer: 'Transfer info' section")
			}
		}
	}
	
	
	// MARK: - Dependencies
	
	var accountService: AccountService!
	var dialogService: DialogService!
	
	
	// MARK: - Properties
	
	var service: WalletServiceWithSend? {
		didSet {
			if let prev = oldValue {
				NotificationCenter.default.removeObserver(self, name: prev.transactionFeeUpdated, object: prev)
			}
			
			if let new = service {
				NotificationCenter.default.addObserver(forName: new.transactionFeeUpdated, object: new, queue: OperationQueue.main) { [weak self] _ in
					guard let fee = self?.service?.transactionFee, let form = self?.form else {
						return
					}
					
					if let row: DecimalRow = form.rowBy(tag: BaseRows.fee.tag) {
						row.value = fee.doubleValue
						row.updateCell()
					}
					
					if let row: DecimalRow = form.rowBy(tag: BaseRows.maxToTransfer.tag) {
						row.updateCell()
					}
					
					self?.validateForm()
				}
			}
		}
	}
	
	
	weak var delegate: TransferViewControllerDelegate?
	
	var recipientAddress: String? = nil {
		didSet {
			if let row: RowOf<String> = form.rowBy(tag: BaseRows.address.tag) {
				row.value = recipientAddress
				row.updateCell()
			}
		}
	}
    
    private var recipientAddressIsValid = false
    
    var recipientName: String? = nil {
        didSet {
            guard let row: RowOf<String> = form.rowBy(tag: BaseRows.name.tag) else {
                return
            }
            
            row.value = recipientName
            row.updateCell()
            row.evaluateHidden()
        }
    }
	
	var admReportRecipient: String? = nil
	var amount: Decimal? = nil
	
	var recipientIsReadonly = false
	
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
	
	
	// MARK: - QR Reader
	
	lazy var qrReader: QRCodeReaderViewController = {
		let builder = QRCodeReaderViewControllerBuilder {
			$0.reader = QRCodeReader(metadataObjectTypes: [.qr ], captureDevicePosition: .back)
			$0.cancelButtonTitle = String.adamantLocalized.alert.cancel
			$0.showSwitchCameraButton = false
		}
		
		let vc = QRCodeReaderViewController(builder: builder)
		vc.delegate = self
		return vc
	}()
	
	
	// MARK: - Alert
	var progressView: UIView? = nil
	var alertView: UIView? = nil
	
	
	// MARK: - Lifecycle
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		// MARK: UI
		navigationAccessoryView.tintColor = UIColor.adamant.primary
        navigationItem.title = defaultSceneTitle()
		
		// MARK: Sections
		form.append(walletSection())
		form.append(recipientSection())
		form.append(transactionInfoSection())
		
        // MARK: - Button section
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
		
		section.append(defaultRowFor(baseRow: BaseRows.balance))
		section.append(defaultRowFor(baseRow: BaseRows.maxToTransfer))
		
		return section
	}
	
	func recipientSection() -> Section {
		let section = Section(Sections.recipient.localized) {
			$0.tag = Sections.recipient.tag
		}
		
        // Name row
        let nameRow = defaultRowFor(baseRow: BaseRows.name)
        section.append(nameRow)
        
        // Address row
		section.append(defaultRowFor(baseRow: BaseRows.address))
		
		if !recipientIsReadonly, let stripe = recipientStripe() {
			var footer = HeaderFooterView<UIView>(.callback {
				let view = ButtonsStripeView.adamantConfigured()
				view.stripe = stripe
				view.delegate = self
				return view
			})
				
			footer.height = { ButtonsStripeView.adamantDefaultHeight }
			
			section.footer = footer
		}
		
		return section
	}
	
	func transactionInfoSection() -> Section {
		let section = Section(Sections.transferInfo.localized) {
			$0.tag = Sections.transferInfo.tag
		}
		
		section.append(defaultRowFor(baseRow: .amount))
		section.append(defaultRowFor(baseRow: .fee))
		section.append(defaultRowFor(baseRow: .total))
		
		return section
	}
	

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
                recipientAddress = address
                markRow(row, valid: true)
                recipientAddressIsValid = true
            } else {
                markRow(row, valid: false)
                recipientAddressIsValid = false
            }
		} else {
			recipientAddress = nil
            recipientAddressIsValid = false
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
    
	
	// MARK: - Send Actions
	
	private func confirmSendFunds() {
		guard let recipient = recipientAddress, let amount = amount else {
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
		
		if admReportRecipient != nil, let account = accountService.account, account.balance < 0.001 {
			dialogService.showWarning(withMessage: "Not enought money to send report")
			return
		}
		
		let formattedAmount = balanceFormatter.string(from: amount as NSDecimalNumber)!
		let title = String.adamantLocalized.alert.confirmSendMessage(formattedAmount: formattedAmount, recipient: recipient)
		
		let alert = UIAlertController(title: title, message: String.adamantLocalized.transfer.cantUndo, preferredStyle: .alert)
		let cancelAction = UIAlertAction(title: String.adamantLocalized.alert.cancel , style: .cancel, handler: nil)
		let sendAction = UIAlertAction(title: String.adamantLocalized.alert.send, style: .default) { [weak self] _ in
			self?.sendFunds()
		}
		
		alert.addAction(cancelAction)
		alert.addAction(sendAction)
		
		present(alert, animated: true, completion: nil)
	}
	
	
	
	// MARK: - 'Virtual' methods with basic implementation
	
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
		
		return balance >= total
	}
	
	func formIsValid() -> Bool {
		if let recipient = recipientAddress, validateRecipient(recipient), let amount = amount, validateAmount(amount), recipientAddressIsValid {
			return true
		} else {
			return false
		}
	}
	
	/// Recipient section footer. You can override this to provide custom set of elements.
	/// You can also override ButtonsStripeViewDelegate implementation
	/// nil for no stripe
	func recipientStripe() -> Stripe? {
		return [.qrCameraReader, .qrPhotoReader]
	}
	
	func reportTransferTo(admAddress: String, transferRecipient: String, amount: Decimal, comments: String, hash: String) {
		
	}
    
    func defaultSceneTitle() -> String? {
        return WalletViewControllerBase.BaseRows.send.localized
    }
    
    
    /// MARK: - Abstract
	
	/// Send funds to recipient after validations
	/// You must override this method
	/// Don't forget to call delegate.transferViewControllerDidFinishTransfer(self) after successfull transfer
	func sendFunds() {
		fatalError("You must implement sending logic")
	}
	
	/// User loaded address from QR (camera or library)
	/// You must override this method
	///
	/// - Parameter address: raw readed address
	/// - Returns: string was successfully handled
	func handleRawAddress(_ address: String) -> Bool {
		fatalError("You must implement raw address handling")
	}
	
	
	/// Build recipient address row
	/// You must override this method
	func recipientRow() -> BaseRow {
		fatalError("You must implement recipient row")
	}
	
	
	/// Validate recipient's address
	/// You must override this method
	func validateRecipient(_ address: String) -> Bool {
		fatalError("You must implement recipient addres validation logic")
	}
	
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


// MARK: - Default rows
extension TransferViewControllerBase {
	func defaultRowFor(baseRow: BaseRows) -> BaseRow {
		switch baseRow {
		case .balance:
			return DecimalRow() { [weak self] in
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
			
        case .name:
            return LabelRow() { [weak self] in
                $0.title = BaseRows.name.localized
                $0.tag = BaseRows.name.tag
                $0.value = self?.recipientName
                $0.hidden = Condition.function([], { form in
                    if let row: RowOf<String> = form.rowBy(tag: BaseRows.name.tag), row.value != nil {
                        return false
                    } else {
                        return true
                    }
                })
            }
            
		case .address:
			return recipientRow()
			
		case .maxToTransfer:
            let row = DecimalRow() { [weak self] in
				$0.title = BaseRows.maxToTransfer.localized
				$0.tag = BaseRows.maxToTransfer.tag
				$0.disabled = true
				$0.formatter = self?.balanceFormatter
                $0.cell.selectionStyle = .gray
				
				if let maxToTransfer = self?.maxToTransfer {
					$0.value = maxToTransfer.doubleValue
				}
            }.onCellSelection { [weak self] (cell, row) in
                guard let value = row.value, value > 0, let presenter = self else {
                    row.deselect(animated: true)
                    return
                }
                
                let alert = UIAlertController(title: String.adamantLocalized.transfer.useMaxToTransfer, message: nil, preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: String.adamantLocalized.alert.cancel , style: .cancel, handler: nil)
                let confirmAction = UIAlertAction(title: String.adamantLocalized.alert.ok, style: .default) { [weak self] _ in
                    guard let amountRow: DecimalRow = self?.form.rowBy(tag: BaseRows.amount.tag) else {
                        return
                    }
                    amountRow.value = value
                    amountRow.updateCell()
                    self?.validateForm()
                }
                
                alert.addAction(cancelAction)
                alert.addAction(confirmAction)
                
                presenter.present(alert, animated: true, completion: {
                    row.deselect(animated: true)
                })
            }
            
            return row
			
		case .amount:
			return DecimalRow { [weak self] in
				$0.title = BaseRows.amount.localized
				$0.placeholder = String.adamantLocalized.transfer.amountPlaceholder
				$0.tag = BaseRows.amount.tag
				$0.formatter = self?.balanceFormatter
				
				if let amount = self?.amount {
					$0.value = amount.doubleValue
				}
			}.onChange { [weak self] (row) in
				self?.validateForm()
			}
		
		case .fee:
			return DecimalRow() { [weak self] in
				$0.tag = BaseRows.fee.tag
				$0.title = BaseRows.fee.localized
				$0.disabled = true
				$0.formatter = self?.balanceFormatter
			
				if let fee = self?.service?.transactionFee {
					$0.value = fee.doubleValue
				} else {
					$0.value = 0
				}
			}
			
		case .total:
			return DecimalRow() { [weak self] in
				$0.tag = BaseRows.total.tag
				$0.title = BaseRows.total.localized
				$0.value = nil
				$0.disabled = true
				$0.formatter = self?.balanceFormatter
				
				if let balance = self?.service?.wallet?.balance {
					$0.add(rule: RuleSmallerOrEqualThan<Double>(max: balance.doubleValue))
				}
			}
		
		case .comments:
			fatalError()
			
		case .sendButton:
			return ButtonRow() { [weak self] in
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
	}
}
