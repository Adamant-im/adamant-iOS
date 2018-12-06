//
//  LskTransferViewController.swift
//  Adamant
//
//  Created by Anton Boyarkin on 27/11/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import Eureka

class LskTransferViewController: TransferViewControllerBase {
    
    // MARK: Dependencies
    
    var chatsProvider: ChatsProvider!
    
    
    // MARK: Properties
    
    override var balanceFormatter: NumberFormatter {
        if let service = service {
            return AdamantBalanceFormat.currencyFormatter(for: .full, currencySymbol: type(of: service).currencySymbol)
        } else {
            return AdamantBalanceFormat.currencyFormatterFull
        }
    }
    
    private var skipValueChange: Bool = false
    
    static let invalidCharacters: CharacterSet = CharacterSet.decimalDigits.inverted
    
    
    // MARK: Send
    
    override func sendFunds() {
        let comments: String
        if let row: TextAreaRow = form.rowBy(tag: BaseRows.comments.tag), let text = row.value {
            comments = text
        } else {
            comments = ""
        }
        
        guard let service = service as? LskWalletService, let recipient = recipientAddress, let amount = amount else {
            return
        }
        
        guard let dialogService = dialogService else {
            return
        }
        
        dialogService.showProgress(withMessage: String.adamantLocalized.transfer.transferProcessingMessage, userInteractionEnable: false)
        
        service.createTransaction(recipient: recipient, amount: amount) { [weak self] result in
            guard let vc = self else {
                dialogService.dismissProgress()
                dialogService.showError(withMessage: String.adamantLocalized.sharedErrors.unknownError, error: nil)
                return
            }
            
            switch result {
            case .success(let transaction):
                // MARK: 1. Send adm report
                if let reportRecipient = vc.admReportRecipient, let hash = transaction.id {
                    let payload = RichMessageTransfer(type: LskWalletService.richMessageType, amount: amount, hash: hash, comments: comments)
                    let message = AdamantMessage.richMessage(payload: payload)
                    
                    vc.chatsProvider.sendMessage(message, recipientId: reportRecipient) { result in
                        if case .failure(let error) = result {
                            vc.dialogService.showRichError(error: error)
                        }
                    }
                }
                
                // MARK: 2. Send LSK transaction
                service.sendTransaction(transaction) { result in
                    switch result {
                    case .success(let hash):
                        service.update()
                        
                        service.getTransaction(by: hash) { result in
                            switch result {
                            case .success(let transaction):
                                vc.dialogService.showSuccess(withMessage: String.adamantLocalized.transfer.transferSuccess)

                                if let detailsVc = vc.router.get(scene: AdamantScene.Wallets.Lisk.transactionDetails) as? LskTransactionDetailsViewController {
                                    detailsVc.transaction = transaction
                                    detailsVc.service = service
                                    detailsVc.senderName = String.adamantLocalized.transactionDetails.yourAddress
                                    detailsVc.recipientName = self?.recipientName

                                    if comments.count > 0 {
                                        detailsVc.comment = comments
                                    }

                                    vc.delegate?.transferViewController(vc, didFinishWithTransfer: transaction, detailsViewController: detailsVc)
                                } else {
                                    vc.delegate?.transferViewController(vc, didFinishWithTransfer: transaction, detailsViewController: nil)
                                }

                            case .failure(let error):
                                // Issue: No transaction - delay of transation processing on server
//                                vc.dialogService.showRichError(error: error)
                                vc.dialogService.showSuccess(withMessage: String.adamantLocalized.transfer.transferSuccess)
                                if let detailsVc = vc.router.get(scene: AdamantScene.Wallets.Lisk.transactionDetails) as? LskTransactionDetailsViewController {
                                    detailsVc.transaction = transaction
                                    detailsVc.service = service
                                    detailsVc.senderName = String.adamantLocalized.transactionDetails.yourAddress
                                    detailsVc.recipientName = self?.recipientName
                                    
                                    if comments.count > 0 {
                                        detailsVc.comment = comments
                                    }
                                    
                                    vc.delegate?.transferViewController(vc, didFinishWithTransfer: transaction, detailsViewController: detailsVc)
                                } else {
                                    vc.delegate?.transferViewController(vc, didFinishWithTransfer: transaction, detailsViewController: nil)
                                }
                                vc.delegate?.transferViewController(vc, didFinishWithTransfer: nil, detailsViewController: nil)
                            }
                        }
                        
                    case .failure(let error):
                        vc.dialogService.showRichError(error: error)
                    }
                }
                
            case .failure(let error):
                dialogService.dismissProgress()
                dialogService.showRichError(error: error)
            }
        }
    }
    
    
    // MARK: Overrides
    
    private var _recipient: String?
    
    override var recipientAddress: String? {
        set {
            if let recipient = newValue, let last = recipient.last, last != "L" {
                _recipient = "\(recipient)L"
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
        
        switch service.validate(address: address) {
        case .valid:
            return true
            
        case .invalid, .system:
            return false
        }
    }
    
    override func recipientRow() -> BaseRow {
        let row = TextRow() {
            $0.tag = BaseRows.address.tag
            $0.cell.textField.placeholder = String.adamantLocalized.newChat.addressPlaceholder
            $0.cell.textField.keyboardType = UIKeyboardType.namePhonePad
            
            if let recipient = recipientAddress {
                let trimmed = recipient.components(separatedBy: LskTransferViewController.invalidCharacters).joined()
                $0.value = trimmed
            }
            
            let suffix = UILabel()
            suffix.text = "L"
            suffix.sizeToFit()
            let view = UIView()
            view.addSubview(suffix)
            view.frame = suffix.frame
            $0.cell.textField.leftView = view
            $0.cell.textField.leftViewMode = .always
            
            if recipientIsReadonly {
                $0.disabled = true
                suffix.isEnabled = false
            }
            }.cellUpdate { (cell, row) in
                if let text = cell.textField.text {
                    cell.textField.text = text.components(separatedBy: LskTransferViewController.invalidCharacters).joined()
                }
            }.onChange { [weak self] row in
                if let skip = self?.skipValueChange, skip {
                    self?.skipValueChange = false
                    return
                }
                
                if let text = row.value {
                    var trimmed = text.components(separatedBy: LskTransferViewController.invalidCharacters).joined()
                    if let last = text.last, last == "L" {
                        trimmed = text.replacingOccurrences(of: "L", with: "")
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
        let payload = RichMessageTransfer(type: LskWalletService.richMessageType, amount: amount, hash: hash, comments: comments)
        
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
    
    override func defaultSceneTitle() -> String? {
        return String.adamantLocalized.sendLsk
    }
}
