//
//  BtcTransferViewController.swift
//  Adamant
//
//  Created by Anton Boyarkin on 08/02/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import UIKit
import Eureka

class BtcTransferViewController: TransferViewControllerBase {
    
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
    
    @MainActor
    override func sendFunds() {
        let comments: String
        if let row: TextAreaRow = form.rowBy(tag: BaseRows.comments.tag), let text = row.value {
            comments = text
        } else {
            comments = ""
        }
        
        guard let service = service as? BtcWalletService, let recipient = recipientAddress, let amount = amount else {
            return
        }
        
        guard let dialogService = dialogService else {
            return
        }
        
        dialogService.showProgress(withMessage: String.adamantLocalized.transfer.transferProcessingMessage, userInteractionEnable: false)
        
        Task {
            do {
                let transaction = try await service.createTransaction(recipient: recipient, amount: amount)
                
                // Send adm report
                // to do: make async and wait before send message
                if let reportRecipient = admReportRecipient,
                   let hash = transaction.txHash {
                    reportTransferTo(admAddress: reportRecipient, amount: amount, comments: comments, hash: hash)
                }
                
                // Send transaction
                let hash = try await service.sendTransaction(transaction)
                
                Task {
                    service.update()
                }
                
                do {
                    let detailTransaction = try await service.getTransaction(by: hash)
                    processSuccessTransaction(self, localTransaction: detailTransaction, service: service, comments: comments, transaction: transaction)
                } catch {
                    let error = error as? ApiServiceError
                    processFailureTransaction(self, service: service, comments: comments, transaction: transaction, error: error)
                }
                dialogService.showSuccess(withMessage: String.adamantLocalized.transfer.transferSuccess)
            } catch {
                dialogService.dismissProgress()
                dialogService.showRichError(error: error)
            }
        }
    }
    
    private func processSuccessTransaction(_ vc: BtcTransferViewController, localTransaction: BtcTransaction, service: BtcWalletService, comments: String, transaction: TransactionDetails) {
        vc.dialogService.showSuccess(withMessage: String.adamantLocalized.transfer.transferSuccess)
        
        if let detailsVc = vc.router.get(scene: AdamantScene.Wallets.Bitcoin.transactionDetails) as? BtcTransactionDetailsViewController {
            detailsVc.transaction = localTransaction
            detailsVc.service = service
            detailsVc.senderName = String.adamantLocalized.transactionDetails.yourAddress
            
            if recipientAddress == service.wallet?.address {
                detailsVc.recipientName = String.adamantLocalized.transactionDetails.yourAddress
            } else {
                detailsVc.recipientName = self.recipientName
            }
            
            if comments.count > 0 {
                detailsVc.comment = comments
            }
            
            vc.delegate?.transferViewController(vc, didFinishWithTransfer: transaction, detailsViewController: detailsVc)
        } else {
            vc.delegate?.transferViewController(vc, didFinishWithTransfer: transaction, detailsViewController: nil)
        }
    }
    
    private func processFailureTransaction(_ vc: BtcTransferViewController, service: BtcWalletService, comments: String, transaction: TransactionDetails, error: ApiServiceError?) {
        if case let .internalError(message, _) = error, message == "No transaction" {
            vc.dialogService.showSuccess(withMessage: String.adamantLocalized.transfer.transferSuccess)
            
            if let detailsVc = vc.router.get(scene: AdamantScene.Wallets.Bitcoin.transactionDetails) as? BtcTransactionDetailsViewController {
                detailsVc.transaction = transaction
                detailsVc.service = service
                detailsVc.senderName = String.adamantLocalized.transactionDetails.yourAddress
                
                if recipientAddress == service.wallet?.address {
                    detailsVc.recipientName = String.adamantLocalized.transactionDetails.yourAddress
                } else {
                    detailsVc.recipientName = self.recipientName
                }
                
                if comments.count > 0 {
                    detailsVc.comment = comments
                }

                vc.delegate?.transferViewController(vc, didFinishWithTransfer: transaction, detailsViewController: detailsVc)
            } else {
                vc.delegate?.transferViewController(vc, didFinishWithTransfer: transaction, detailsViewController: nil)
            }
        } else {
            if let error = error {
                vc.dialogService.showRichError(error: error)
            }
            vc.delegate?.transferViewController(vc, didFinishWithTransfer: nil, detailsViewController: nil)
        }
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
            
            if let recipient = recipientAddress {
                $0.value = recipient
            }
            
            if recipientIsReadonly {
                $0.disabled = true
            }
        }.onChange { [weak self] row in
            if let text = row.value {
                self?._recipient = text
            }

            if let skip = self?.skipValueChange, skip {
                self?.skipValueChange = false
                return
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
        if address.hasPrefix("bitcoin:"), let firstIndex = address.firstIndex(of: ":") {
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
    
    func reportTransferTo(admAddress: String, amount: Decimal, comments: String, hash: String) {
        let payload = RichMessageTransfer(type: BtcWalletService.richMessageType, amount: amount, hash: hash, comments: comments)
        
        let message = AdamantMessage.richMessage(payload: payload)
        
        chatsProvider.sendMessage(message, recipientId: admAddress) { [weak self] result in
            if case .failure(let error) = result {
                self?.dialogService.showRichError(error: error)
            }
        }
    }
    
    override func defaultSceneTitle() -> String? {
        return String.adamantLocalized.sendBtc
    }
}
