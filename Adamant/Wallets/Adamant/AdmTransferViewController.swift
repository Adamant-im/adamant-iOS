//
//  AdmTransferViewController.swift
//  Adamant
//
//  Created by Anokhov Pavel on 18.08.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import Eureka

class AdmTransferViewController: TransferViewControllerBase {
	// MARK: Properties
	
	override var balanceFormatter: NumberFormatter {
		return AdamantUtilities.currencyFormatter
	}
	
	private var skipValueChange: Bool = false
	
	static let invalidCharactersSet = CharacterSet.decimalDigits.inverted
	
	// MARK: Sending
	
	override func sendFunds() {
		guard let service = service as? AdmWalletService, let recipient = recipient, let amount = amount else {
			return
		}
		
		dialogService.showProgress(withMessage: String.adamantLocalized.transfer.transferProcessingMessage, userInteractionEnable: false)
		
		service.sendMoney(recipient: recipient, amount: amount, comments: "") { [weak self] result in
			switch result {
			case .success:
				service.update()
				
				guard let vc = self else {
					break
				}
				
				vc.dialogService?.showSuccess(withMessage: String.adamantLocalized.transfer.transferSuccess)
				vc.delegate?.transferViewControllerDidFinishTransfer(vc)
				
			case .failure(let error):
				guard let dialogService = self?.dialogService else {
					break
				}
				
				dialogService.dismissProgress()
				dialogService.showRichError(error: error)
			}
		}
	}
	
	
	// MARK: Overrides
	
	private var _recipient: String?
	
	override var recipient: String? {
		set {
			if let recipient = newValue, let first = recipient.first, first != "U" {
				_recipient = "U\(recipient)"
			} else {
				_recipient = newValue
			}
			
			if let row: TextRow = form.rowBy(tag: BaseRows.address.tag) {
				row.value = _recipient
				row.updateCell()
			}
		}
		get {
			return _recipient
		}
	}
	
	override func recipientRow() -> BaseRow {
		let row = TextRow() {
			$0.tag = BaseRows.address.tag
			$0.cell.textField.placeholder = String.adamantLocalized.newChat.addressPlaceholder
			$0.cell.textField.keyboardType = .numberPad
			
			if let recipient = recipient {
				let trimmed = recipient.components(separatedBy: AdmTransferViewController.invalidCharactersSet).joined()
				$0.value = trimmed
			}
			
			let prefix = UILabel()
			prefix.text = "U"
			prefix.sizeToFit()
			let view = UIView()
			view.addSubview(prefix)
			view.frame = prefix.frame
			$0.cell.textField.leftView = view
			$0.cell.textField.leftViewMode = .always
			
			if recipientIsReadonly {
				$0.disabled = true
				prefix.isEnabled = false
			}
		}.cellUpdate { (cell, row) in
			if let text = cell.textField.text {
				cell.textField.text = text.components(separatedBy: AdmTransferViewController.invalidCharactersSet).joined()
			}
		}.onChange { [weak self] row in
			if let skip = self?.skipValueChange, skip {
				self?.skipValueChange = false
				return
			}
			
			if let text = row.value {
				let trimmed = text.components(separatedBy: AdmTransferViewController.invalidCharactersSet).joined()
				
				if text != trimmed {
					self?.skipValueChange = true
					
					DispatchQueue.main.async {
						row.value = trimmed
						row.updateCell()
					}
				}
			}
			
			self?.validateForm()
		}
		
		return row
	}
	
	override func validateRecipient(_ address: String) -> Bool {
		let fixedAddress: String
		if let first = address.first, first != "U" {
			fixedAddress = "U\(address)"
		} else {
			fixedAddress = address
		}
		
		switch AdamantUtilities.validateAdamantAddress(address: fixedAddress) {
		case .valid:
			return true
			
		case .system, .invalid:
			return false
		}
	}
	
	override func handleRawAddress(_ address: String) -> Bool {
		guard let uri = AdamantUriTools.decode(uri: address) else {
			return false
		}
		
		switch uri {
		case .address(let address, _):
			if let row: TextRow = form.rowBy(tag: BaseRows.address.tag) {
				row.value = address
				row.updateCell()
			}
			
			return true
			
		default:
			return false
		}
	}
}
