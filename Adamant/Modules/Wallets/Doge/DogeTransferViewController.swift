//
//  DogeTransferViewController.swift
//  Adamant
//
//  Created by Anton Boyarkin on 12/03/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import UIKit
import Eureka
import BitcoinKit
import CommonKit

final class DogeTransferViewController: TransferViewControllerBase {

    // MARK: Send
    
    @MainActor
    override func sendFunds() {
        let comments: String
        if let row: TextAreaRow = form.rowBy(tag: BaseRows.comments.tag), let text = row.value {
            comments = text
        } else {
            comments = ""
        }
        
        guard let service = walletCore as? DogeWalletService,
              let recipient = recipientAddress,
              let amount = amount
        else {
            return
        }
        
        guard let wallet = service.wallet else {
            return
        }
        
        dialogService.showProgress(withMessage: String.adamant.transfer.transferProcessingMessage, userInteractionEnable: false)
        
        Task {
            do {
                // Create transaction
                let transaction = try await service.createTransaction(
                    recipient: recipient, 
                    amount: amount,
                    fee: transactionFee
                )
                
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
                
                do {
                    let simpleTransaction = SimpleTransactionDetails(
                        txId: transaction.txID,
                        senderAddress: wallet.address,
                        recipientAddress: recipient,
                        amountValue: amount,
                        feeValue: nil,
                        confirmationsValue: nil,
                        blockValue: nil,
                        isOutgoing: true,
                        transactionStatus: nil
                    )
                    
                    service.coinStorage.append(simpleTransaction)
                    try await service.sendTransaction(transaction)
                } catch {
                    service.coinStorage.updateStatus(
                        for: transaction.txId,
                        status: .failed
                    )
                    
                    throw error
                }
                
                Task {
                    await service.update()
                }
                
                dialogService.dismissProgress()
                dialogService.showSuccess(withMessage: String.adamant.transfer.transferSuccess)
                
                // Present detail VC
                presentDetailTransactionVC(
                    transaction: transaction,
                    comments: comments,
                    service: walletService
                )
            } catch {
                dialogService.dismissProgress()
                dialogService.showRichError(error: error)
            }
        }
    }
    
    private func presentDetailTransactionVC(
        transaction: BitcoinKit.Transaction,
        comments: String,
        service: WalletService
    ) {
        let detailsVc = screensFactory.makeDetailsVC(service: service)
        detailsVc.transaction = transaction
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
    }
    
    // MARK: Overrides
    
    override func recipientRow() -> BaseRow {
        let row = TextRow {
            $0.tag = BaseRows.address.tag
            $0.cell.textField.placeholder = String.adamant.newChat.addressPlaceholder
            $0.cell.textField.keyboardType = .namePhonePad
            $0.cell.textField.autocorrectionType = .no
            $0.cell.textField.setLineBreakMode()
            
            $0.value = recipientAddress?.components(
                separatedBy: TransferViewControllerBase.invalidCharacters
            ).joined()
            
            if recipientIsReadonly {
                $0.disabled = true
                $0.cell.textField.isEnabled = false
            }
        }.cellUpdate { cell, row in
            cell.textField.text = row.value?.components(
                separatedBy: TransferViewControllerBase.invalidCharacters
            ).joined()
        }.onChange { [weak self] row in
            row.cell.textField.text = row.value?.components(
                separatedBy: TransferViewControllerBase.invalidCharacters
            ).joined()
            
            self?.updateToolbar(for: row)
        }.onCellSelection { [weak self] (cell, _) in
            self?.shareValue(self?.recipientAddress, from: cell)
        }
        
        return row
    }
    
    override func defaultSceneTitle() -> String? {
        return String.adamant.sendDoge
    }
}
