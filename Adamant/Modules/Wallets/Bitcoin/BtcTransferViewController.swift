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
    
    private var skipValueChange: Bool = false
    
    // MARK: Send
    
    @MainActor
    override func sendFunds() {
        let comments: String
        if let row: TextAreaRow = form.rowBy(tag: BaseRows.comments.tag), let text = row.value {
            comments = text
        } else {
            comments = ""
        }
        
        guard let service = walletCore as? BtcWalletService,
              let recipient = recipientAddress,
              let amount = amount,
              let wallet = service.wallet
        else {
            return
        }
        
        dialogService.showProgress(withMessage: String.adamant.transfer.transferProcessingMessage, userInteractionEnable: false)
        
        Task {
            do {
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
                
                Task {
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
                        dialogService.showRichError(error: error)
                        service.coinStorage.updateStatus(
                            for: transaction.txId,
                            status: .failed
                        )
                    }
                    
                    await service.update()
                }
                
                var detailTransaction: BtcTransaction?
                if let hash = transaction.txHash {
                    detailTransaction = try? await service.getTransaction(by: hash)
                }
                
                processTransaction(
                    self,
                    localTransaction: detailTransaction,
                    service: walletService,
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
        service: WalletService,
        comments: String,
        transaction: TransactionDetails
    ) {
        vc.dialogService.showSuccess(withMessage: String.adamant.transfer.transferSuccess)
        
        let detailsVc = screensFactory.makeDetailsVC(service: service)
        detailsVc.transaction = localTransaction ?? transaction
        detailsVc.senderName = String.adamant.transactionDetails.yourAddress
        
        if recipientAddress == service.core.wallet?.address {
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
    
    override func recipientRow() -> BaseRow {
        let row = TextRow {
            $0.tag = BaseRows.address.tag
            $0.cell.textField.placeholder = String.adamant.newChat.addressPlaceholder
            $0.cell.textField.setLineBreakMode()
            $0.cell.textField.keyboardType = .namePhonePad
            $0.cell.textField.autocorrectionType = .no
            
            $0.value = recipientAddress?.components(
                separatedBy: TransferViewControllerBase.invalidCharacters
            ).joined()
            
            if recipientIsReadonly {
                $0.disabled = true
            }
        }.cellUpdate { cell, row in
            cell.textField.text = row.value?.components(
                separatedBy: TransferViewControllerBase.invalidCharacters
            ).joined()
        }.onChange { [weak self] row in
            if let skip = self?.skipValueChange, skip {
                self?.skipValueChange = false
                return
            }
            
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
        return String.adamant.sendBtc
    }
}
