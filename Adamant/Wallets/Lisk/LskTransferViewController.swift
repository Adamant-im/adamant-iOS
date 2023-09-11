//
//  LskTransferViewController.swift
//  Adamant
//
//  Created by Anton Boyarkin on 27/11/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import Eureka
import LiskKit
import CommonKit

final class LskTransferViewController: TransferViewControllerBase {
    
    // MARK: Properties
    
    override var minToTransfer: Decimal {
        get async throws {
            guard let recipientAddress = recipientAddress else {
                throw WalletServiceError.accountNotFound
            }
            
            guard let service = service else {
                throw WalletServiceError.walletNotInitiated
            }
            
            let recepientBalance = try await service.getBalance(address: recipientAddress)
            let minimumAmount = service.minBalance - recepientBalance
            return try await max(super.minToTransfer, minimumAmount)
        }
    }
    
    // MARK: Send
    
    @MainActor
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
        
        dialogService.showProgress(withMessage: String.adamant.transfer.transferProcessingMessage, userInteractionEnable: false)
        
        Task {
            do {
                // Create transaction
                let transaction = try await service.createTransaction(recipient: recipient, amount: amount)
                
                // Send adm report
                if let reportRecipient = admReportRecipient {
                    try await reportTransferTo(
                        admAddress: reportRecipient,
                        amount: amount,
                        comments: comments,
                        hash: transaction.id
                    )
                }
                
                Task {
                    do {
                        try await service.sendTransaction(transaction)
                    } catch {
                        dialogService.showRichError(error: error)
                    }
                    
                    await service.update()
                }
                
                dialogService.dismissProgress()
                dialogService.showSuccess(withMessage: String.adamant.transfer.transferSuccess)
                
                // Present detail VC
                presentDetailTransactionVC(
                    transactionId: transaction.id,
                    transaction: transaction,
                    service: service,
                    comments: comments
                )
            } catch {
                dialogService.dismissProgress()
                dialogService.showRichError(error: error)
            }
        }
    }
    
    private func presentDetailTransactionVC(
        transactionId: String,
        transaction: TransactionEntity,
        service: LskWalletService,
        comments: String
    ) {
        if let detailsVc = router.get(scene: AdamantScene.Wallets.Lisk.transactionDetails) as? LskTransactionDetailsViewController {
            var transaction: TransactionEntity = transaction
            transaction.id = transactionId
            detailsVc.transaction = transaction
            detailsVc.service = service
            detailsVc.senderName = String.adamant.transactionDetails.yourAddress
            detailsVc.recipientName = recipientName
            
            if comments.count > 0 {
                detailsVc.comment = comments
            }
            
            delegate?.transferViewController(
                self,
                didFinishWithTransfer: transaction,
                detailsViewController: detailsVc
            )
        } else {
            delegate?.transferViewController(
                self,
                didFinishWithTransfer: transaction,
                detailsViewController: nil
            )
        }
    }
    
    // MARK: Overrides
    
    override func validateRecipient(_ address: String) -> AddressValidationResult {
        service?.validate(address: address) ?? .invalid(description: nil)
    }
    
    override func recipientRow() -> BaseRow {
        let row = TextRow {
            $0.tag = BaseRows.address.tag
            $0.cell.textField.placeholder = String.adamant.newChat.addressPlaceholder
            $0.cell.textField.keyboardType = UIKeyboardType.alphabet
            $0.cell.textField.autocorrectionType = .no
            $0.cell.textField.setLineBreakMode()
            
            if let recipient = recipientAddress {
                $0.value = recipient
            }

            if recipientIsReadonly {
                $0.disabled = true
                $0.cell.textField.isEnabled = false
            }
        }.onChange { [weak self] row in
            self?.updateToolbar(for: row)
        }.onCellSelection { [weak self] (cell, _) in
            self?.shareValue(self?.recipientAddress, from: cell)
        }

        return row
    }
    
    override func defaultSceneTitle() -> String? {
        return String.adamant.sendLsk
    }
}
