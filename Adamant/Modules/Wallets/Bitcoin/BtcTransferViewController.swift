//
//  BtcTransferViewController.swift
//  Adamant
//
//  Created by Anton Boyarkin on 08/02/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import UIKit
import Eureka
import CommonKit

final class BtcTransferViewController: TransferViewControllerBase {
    
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
        
        dialogService.showProgress(withMessage: String.adamant.transfer.transferProcessingMessage, userInteractionEnable: false)
        
        Task {
            do {
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
                
                Task {
                    do {
                        try await service.sendTransaction(transaction)
                    } catch {
                        dialogService.showRichError(error: error)
                    }
                    
                    try await service.update()
                }
                
                var detailTransaction: BtcTransaction?
                if let hash = transaction.txHash {
                    detailTransaction = try? await service.getTransaction(by: hash)
                }
                
                processTransaction(
                    self,
                    localTransaction: detailTransaction,
                    service: service,
                    comments: comments,
                    transaction: transaction
                )
                
                dialogService.dismissProgress()
                dialogService.showSuccess(withMessage: String.adamant.transfer.transferSuccess)
            } catch {
                dialogService.dismissProgress()
                dialogService.showRichError(error: error)
            }
        }
    }
    
    private func processTransaction(
        _ vc: BtcTransferViewController,
        localTransaction: BtcTransaction?,
        service: BtcWalletService,
        comments: String,
        transaction: TransactionDetails
    ) {
        vc.dialogService.showSuccess(withMessage: String.adamant.transfer.transferSuccess)
        
        let detailsVc = screensFactory.makeDetailsVC(service: service)
        detailsVc.transaction = localTransaction ?? transaction
        detailsVc.senderName = String.adamant.transactionDetails.yourAddress
        
        if recipientAddress == service.wallet?.address {
            detailsVc.recipientName = String.adamant.transactionDetails.yourAddress
        } else {
            detailsVc.recipientName = self.recipientName
        }
        
        if comments.count > 0 {
            detailsVc.comment = comments
        }
        
        vc.delegate?.transferViewController(
            vc,
            didFinishWithTransfer: transaction,
            detailsViewController: detailsVc
        )
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
    
    override func validateRecipient(_ address: String) -> AddressValidationResult {
        service?.validate(address: address) ?? .invalid(description: nil)
    }
    
    override func recipientRow() -> BaseRow {
        let row = TextRow {
            $0.tag = BaseRows.address.tag
            $0.cell.textField.placeholder = String.adamant.newChat.addressPlaceholder
            $0.cell.textField.setLineBreakMode()
            
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
    
    
    
    
    override func defaultSceneTitle() -> String? {
        return String.adamant.sendBtc
    }
}
