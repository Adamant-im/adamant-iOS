//
//  EthTransferViewController.swift
//  Adamant
//
//  Created by Anokhov Pavel on 23.08.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import Eureka

class EthTransferViewController: TransferViewControllerBase {
	
	// MARK: Dependencies
	
	var chatsProvider: ChatsProvider!
	
	
	// MARK: Properties
	
	override var balanceFormatter: NumberFormatter {
		if let service = service {
			return AdamantBalanceFormat.currencyFormatter(format: .full, currencySymbol: type(of: service).currencySymbol)
		} else {
			return AdamantBalanceFormat.currencyFormatterFull
		}
	}
	
	private var skipValueChange: Bool = false
	
	static let invalidCharacters: CharacterSet = {
		CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789").inverted
	}()
	
	
	// MARK: Overrides
	
	private var _recipient: String?
	
	override var recipient: String? {
		set {
			if let recipient = newValue, let first = recipient.first, first != "0" {
				_recipient = "0x\(recipient)"
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
	
	override func validateRecipient(_ address: String) -> Bool {
		guard let service = service else {
			return false
		}
		
		let fixedAddress: String
		if let first = address.first, first != "0" {
			fixedAddress = "0x\(address)"
		} else {
			fixedAddress = address
		}
		
		switch service.validate(address: fixedAddress) {
		case .valid:
			return true
			
		case .invalid, .system:
			return true
		}
	}
	
	override func recipientRow() -> BaseRow {
		let row = TextRow() {
			$0.tag = BaseRows.address.tag
			$0.cell.textField.placeholder = String.adamantLocalized.newChat.addressPlaceholder
			$0.cell.textField.keyboardType = UIKeyboardType.namePhonePad
			
			if let recipient = recipient {
				let trimmed = recipient.components(separatedBy: EthTransferViewController.invalidCharacters).joined()
				$0.value = trimmed
			}
			
			let prefix = UILabel()
			prefix.text = "0x"
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
				cell.textField.text = text.components(separatedBy: EthTransferViewController.invalidCharacters).joined()
			}
		}.onChange { [weak self] row in
			if let skip = self?.skipValueChange, skip {
				self?.skipValueChange = false
				return
			}
			
			if let text = row.value {
				var trimmed = text.components(separatedBy: EthTransferViewController.invalidCharacters).joined()
				if trimmed.starts(with: "0x") {
					let i = trimmed.index(trimmed.startIndex, offsetBy: 2)
					trimmed = String(trimmed[i...])
				}
				
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
	
	override func handleRawAddress(_ address: String) -> Bool {
		guard let service = service else {
			return false
		}
		
		switch service.validate(address: address) {
		case .valid:
			if let row: TextRow = form.rowBy(tag: BaseRows.address.tag) {
				row.value = address
				row.updateCell()
			}
			
			return true
			
		default:
			return false
		}
	}
	
	override func reportTransferTo(admAddress: String, transferRecipient: String, amount: Decimal, comments: String, hash: String) {
		let payload = RichMessageTransfer(type: RichMessageType.ethTransfer, amount: amount, hash: hash, comments: comments)
		let message = AdamantMessage.richMessage(payload: payload)
		
		chatsProvider.sendMessage(message, recipientId: admAddress) { [weak self] result in
			switch result {
			case .success:
				break
				
			case .failure(let error):
				self?.dialogService.showRichError(error: error)
			}
		}
	}
}
