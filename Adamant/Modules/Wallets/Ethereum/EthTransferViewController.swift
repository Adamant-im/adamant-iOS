//
//  EthTransferViewController.swift
//  Adamant
//
//  Created by Anokhov Pavel on 23.08.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import Eureka
import Web3Core
import CommonKit

final class EthTransferViewController: TransferViewControllerBase {
    
    // MARK: Properties
    
    private var skipValueChange: Bool = false
    private let prefix = "0x"
    
    // MARK: Send
    
    @MainActor
    override func sendFunds() {
        let comments: String
        if let row: TextAreaRow = form.rowBy(tag: BaseRows.comments.tag), let text = row.value {
            comments = text
        } else {
            comments = ""
        }
        
        guard let service = service as? EthWalletService, let recipient = recipientAddress, let amount = amount else {
            return
        }
        
        dialogService.showProgress(withMessage: String.adamant.transfer.transferProcessingMessage, userInteractionEnable: false)
        
        Task {
            do {
                // Create transaction
                let transaction = try await service.createTransaction(recipient: recipient, amount: amount)
                
                guard let txHash = transaction.txHash else {
                    throw WalletServiceError.internalError(
                        message: "Transaction making failure",
                        error: nil
                    )
                }
                
                // Send adm report
                if let reportRecipient = admReportRecipient {
                    try await reportTransferTo(
                        admAddress: reportRecipient,
                        amount: amount,
                        comments: comments,
                        hash: txHash
                    )
                }
                
                Task {
                    do {
                        try await service.sendTransaction(transaction)
                    } catch {
                        dialogService.showRichError(error: error)
                        service.coinStorage.updateStatus(
                            for: txHash,
                            status: .failed
                        )
                    }
                    
                    await service.update()
                }
                
                dialogService.dismissProgress()
                dialogService.showSuccess(withMessage: String.adamant.transfer.transferSuccess)
                
                // Present detail VC
                presentDetailTransactionVC(
                    hash: txHash,
                    transaction: transaction,
                    recipient: recipient,
                    comments: comments,
                    amount: amount,
                    service: service
                )
            } catch {
                dialogService.dismissProgress()
                dialogService.showRichError(error: error)
            }
        }
    }
    
    private func presentDetailTransactionVC(
        hash: String,
        transaction: CodableTransaction,
        recipient: String,
        comments: String,
        amount: Decimal,
        service: EthWalletService
    ) {
        let transaction = SimpleTransactionDetails(
            txId: hash,
            senderAddress: transaction.sender?.address ?? "",
            recipientAddress: recipient,
            amountValue: amount,
            feeValue: nil,
            confirmationsValue: nil,
            blockValue: nil,
            isOutgoing: true,
            transactionStatus: nil
        )
        
        service.coinStorage.append(transaction)
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
            $0.cell.textField.setLineBreakMode()
            
            if recipientIsReadonly {
                $0.disabled = true
                prefixLabel.textColor = UIColor.lightGray
            }
        }.cellUpdate { [weak self] (cell, _) in
            if let text = cell.textField.text {
                cell.textField.text = text.components(separatedBy: TransferViewControllerBase.invalidCharacters).joined()

                guard self?.recipientIsReadonly == false else { return }
        
                cell.textField.leftView?.subviews.forEach { view in
                    guard let label = view as? UILabel else { return }
                    label.textColor = UIColor.adamant.primary
                }
            }
        }.onChange { [weak self] row in
            if let skip = self?.skipValueChange, skip {
                self?.skipValueChange = false
                return
            }
            
            if let text = row.value {
                var trimmed = text.components(
                    separatedBy: TransferViewControllerBase.invalidCharacters
                ).joined()
                
                if let prefix = self?.prefix,
                   trimmed.starts(with: prefix) {
                    let i = trimmed.index(trimmed.startIndex, offsetBy: prefix.count)
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
            self?.updateToolbar(for: row)
        }.onCellSelection { [weak self] (cell, _) in
            self?.shareValue(self?.recipientAddress, from: cell)
        }
        
        return row
    }
    
    override func defaultSceneTitle() -> String? {
        return String.adamant.wallets.sendEth
    }
}
