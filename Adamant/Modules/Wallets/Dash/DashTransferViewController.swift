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
import CommonKit

extension String.adamant.transfer {
    static var minAmountError: String { String.localized("TransferScene.Error.MinAmount", comment: "Transfer: Minimal transaction amount is 0.00001")
    }
    static func pendingTxError(coin: String) -> String {
        let localizedString = String(
            format: .localized("TransferScene.Error.Pending.Tx", comment: "Have a pending coin tx"), 
            coin
        )
        return localizedString
    }
}

final class DashTransferViewController: TransferViewControllerBase {
    
    // MARK: Send
    
    @MainActor
    override func sendFunds() {
        let comments: String
        if let row: TextAreaRow = form.rowBy(tag: BaseRows.comments.tag), let text = row.value {
            comments = text
        } else {
            comments = ""
        }
        
        guard let service = walletCore as? DashWalletService,
              let recipient = recipientAddress,
              let amount = amount
        else {
            return
        }
        
        let history = service.getLocalTransactionHistory()
        var havePending = false
        for transaction in history {
            if case (.pending) = transaction.transactionStatus {
                havePending = true
            }
            if case (.registered) = transaction.transactionStatus {
                havePending = true
            }
        }
        if havePending {
            dialogService.showAlert(
                title: nil,
                message: String.adamant.transfer.pendingTxError(coin: DashWalletService.tokenNetworkSymbol),
                style: AdamantAlertStyle.alert,
                actions: nil,
                from: nil
            )
            return
        }
        
        guard amount >= 0.00001 else {
            dialogService.showAlert(
                title: nil,
                message: String.adamant.transfer.minAmountError,
                style: AdamantAlertStyle.alert,
                actions: nil,
                from: nil
            )
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
        return String.adamant.sendDash
    }
}
