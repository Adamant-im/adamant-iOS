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

@MainActor
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
    
    private let prefix = "lsk"
    
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
                        service.coinStorage.append(transaction)
                        try await service.sendTransaction(transaction)
                        service.coinStorage.updateStatus(
                            for: transaction.id,
                            status: .registered
                        )
                    } catch {
                        dialogService.showRichError(error: error)
                        service.coinStorage.updateStatus(
                            for: transaction.id,
                            status: .failed
                        )
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
        let detailsVc = screensFactory.makeDetailsVC(service: service)
        var transaction: TransactionEntity = transaction
        transaction.id = transactionId
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
    
    override var recipientAddress: String? {
        set {
            let _recipient = newValue?.addPrefixIfNeeded(prefix: prefix)
            
            if let row: TextRow = form.rowBy(tag: BaseRows.address.tag) {
                row.value = _recipient
                row.updateCell()
            }
        }
        get {
            let row: RowOf<String>? = form.rowBy(tag: BaseRows.address.tag)
            return row?.value?.addPrefixIfNeeded(prefix: prefix)
        }
    }
    
    override func validateRecipient(_ address: String) -> AddressValidationResult {
        let fixedAddress = address.addPrefixIfNeeded(prefix: prefix)
        return service?.validate(address: fixedAddress) ?? .invalid(description: nil)
    }
    
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

            let prefixLabel = UILabel()
            prefixLabel.text = prefix
            prefixLabel.sizeToFit()
            
            let view = UIView()
            view.addSubview(prefixLabel)
            view.frame = prefixLabel.frame
            $0.cell.textField.leftView = view
            $0.cell.textField.leftViewMode = .always
            
            if recipientIsReadonly {
                $0.disabled = true
                $0.cell.textField.isEnabled = false
                prefixLabel.textColor = .lightGray
            }
        }.cellUpdate { [weak self] cell, row in
            cell.textField.text = row.value?.components(
                separatedBy: TransferViewControllerBase.invalidCharacters
            ).joined()
            
            guard self?.recipientIsReadonly == false else { return }
    
            cell.textField.leftView?.subviews.forEach { view in
                guard let label = view as? UILabel else { return }
                label.textColor = UIColor.adamant.primary
            }
        }.onChange { [weak self] row in
            var trimmed = row.value?.components(
                separatedBy: TransferViewControllerBase.invalidCharacters
            ).joined() ?? ""
            
            if let prefix = self?.prefix,
               trimmed.starts(with: prefix) {
                let i = trimmed.index(trimmed.startIndex, offsetBy: prefix.count)
                trimmed = String(trimmed[i...])
            }
            
            row.value = trimmed
            row.updateCell()
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
