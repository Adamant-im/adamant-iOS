//
//  DashTransferViewController.swift
//  Adamant
//
//  Created by Anton Boyarkin on 26/05/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import UIKit
import Eureka
import BitcoinKit

extension String.adamantLocalized.transfer {
        static let minAmountError = NSLocalizedString("TransferScene.Error.MinAmount", comment: "Transfer: Minimal transaction amount is 0.00001")
}

class DashTransferViewController: TransferViewControllerBase {
    
    // MARK: Dependencies
    
    var chatsProvider: ChatsProvider!
    
    // MARK: Properties
    
    static let invalidCharacters: CharacterSet = CharacterSet.decimalDigits.inverted
    
    // MARK: Send
    
    @MainActor
    override func sendFunds() {
        let comments: String
        if let row: TextAreaRow = form.rowBy(tag: BaseRows.comments.tag), let text = row.value {
            comments = text
        } else {
            comments = ""
        }
        
        guard let service = service as? DashWalletService, let recipient = recipientAddress, let amount = amount, let dialogService = dialogService else {
            return
        }
        
        guard amount >= 0.00001 else {
            dialogService.showAlert(title: nil, message: String.adamantLocalized.transfer.minAmountError, style: AdamantAlertStyle.alert, actions: nil, from: nil)
            return
        }
        
        guard let sender = service.wallet?.address else {
            return
        }
        
        dialogService.showProgress(withMessage: String.adamantLocalized.transfer.transferProcessingMessage, userInteractionEnable: false)
        
        Task {
            do {
                // Create transaction
                let transaction = try await service.createTransaction(recipient: recipient, amount: amount)
                
                // Send adm report
                if let reportRecipient = admReportRecipient,
                   let hash = transaction.txHash {
                    try await reportTransferTo(
                        admAddress: reportRecipient,
                        amount: amount,
                        comments: comments,
                        hash: hash
                    )
                }
                
                // Send transaction
                let hash = try await service.sendTransaction(transaction)
                
                Task {
                    service.update()
                }
                
                dialogService.dismissProgress()
                dialogService.showSuccess(withMessage: String.adamantLocalized.transfer.transferSuccess)
                
                // Present detail VC
                presentDetailTransactionVC(transaction: transaction,
                                           comments: comments,
                                           service: service
                )
            } catch {
                dialogService.dismissProgress()
                dialogService.showRichError(error: error)
            }
        }
    }
    
    private func presentDetailTransactionVC(transaction: BitcoinKit.Transaction,
                                            comments: String,
                                            service: DashWalletService
    ) {
        guard let detailsVc = router.get(scene: AdamantScene.Wallets.Dash.transactionDetails) as? DashTransactionDetailsViewController else {
            delegate?.transferViewController(self, didFinishWithTransfer: transaction, detailsViewController: nil)
            return
        }
        
        detailsVc.transaction = transaction
        detailsVc.service = service
        detailsVc.senderName = String.adamantLocalized.transactionDetails.yourAddress
        detailsVc.recipientName = recipientName
        
        if comments.count > 0 {
            detailsVc.comment = comments
        }
        
        delegate?.transferViewController(self, didFinishWithTransfer: transaction, detailsViewController: detailsVc)
    }
    
    // MARK: Overrides
    
    private var _recipient: String?
    
    override var recipientAddress: String? {
        set {
            _recipient = newValue
            
            if let row: RowOf<String> = form.rowBy(tag: BaseRows.address.tag) {
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
        let row = TextRow {
            $0.tag = BaseRows.address.tag
            $0.cell.textField.placeholder = String.adamantLocalized.newChat.addressPlaceholder
            $0.cell.textField.autocorrectionType = .no
            
            if let recipient = recipientAddress {
                $0.value = recipient
            }
            
            if recipientIsReadonly {
                $0.disabled = true
                $0.cell.textField.isEnabled = false
            }
        }.onChange { [weak self] row in
            if let text = row.value {
                self?._recipient = text
            }
            self?.updateToolbar(for: row)
        }.onCellSelection { [weak self] (cell, _) in
            self?.shareValue(self?.recipientAddress, from: cell)
        }
        
        return row
    }
    
    override func handleRawAddress(_ address: String) -> Bool {
        guard let service = service else {
            return false
        }
        
        let parsedAddress: String
        if address.hasPrefix("dash:"), let firstIndex = address.firstIndex(of: ":") {
            let index = address.index(firstIndex, offsetBy: 1)
            parsedAddress = String(address[index...])
        } else {
            parsedAddress = address
        }
        
        switch service.validate(address: parsedAddress) {
        case .valid:
            if let row: RowOf<String> = form.rowBy(tag: BaseRows.address.tag) {
                row.value = parsedAddress
                row.updateCell()
            }
            
            return true
            
        default:
            return false
        }
    }
    
    func reportTransferTo(
        admAddress: String,
        amount: Decimal,
        comments: String,
        hash: String
    ) async throws {
        let payload = RichMessageTransfer(type: DashWalletService.richMessageType, amount: amount, hash: hash, comments: comments)
        
        let message = AdamantMessage.richMessage(payload: payload)
        
        await chatsProvider.removeChatPositon(for: admAddress)
        _ = try await chatsProvider.sendMessage(message, recipientId: admAddress)
    }
    
    override func defaultSceneTitle() -> String? {
        return String.adamantLocalized.sendDash
    }
}
