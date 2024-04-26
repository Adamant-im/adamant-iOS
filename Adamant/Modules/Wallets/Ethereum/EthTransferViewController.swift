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
        
        guard let service = walletCore as? EthWalletService,
              let recipient = recipientAddress,
              let amount = amount
        else {
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
                
                if await !doesNotContainSendingTx(
                    with: Int(transaction.nonce),
                    id: transaction.txHash,
                    service: service
                ) {
                    presentSendingError()
                    return
                }
                
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
                
                do {
                    try await service.sendTransaction(transaction)
                } catch {
                    service.coinStorage.updateStatus(
                        for: txHash,
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
                    hash: txHash,
                    transaction: transaction,
                    recipient: recipient,
                    comments: comments,
                    amount: amount,
                    service: walletService
                )
            } catch {
                dialogService.dismissProgress()
                dialogService.showRichError(error: error)
            }
        }
    }
    
    private func doesNotContainSendingTx(
        with nonce: Int,
        id: String?,
        service: EthWalletService
    ) async -> Bool {
        var history = service.getLocalTransactionHistory()
        
        if history.isEmpty {
            history = (try? await service.getTransactionsHistory(offset: .zero, limit: 2)) ?? []
        }
        
        let pendingTx = history.first(where: {
            $0.transactionStatus == .pending
            || $0.transactionStatus == .registered
            || $0.transactionStatus == .notInitiated
            || $0.txId == id
        })
                
        guard let pendingTx = pendingTx else {
            return true
        }
        
        guard let detailTx = try? await service.getTransaction(by: pendingTx.txId) else {
            return false
        }
        
        return detailTx.nonce != nonce
    }
    
    private func presentDetailTransactionVC(
        hash: String,
        transaction: CodableTransaction,
        recipient: String,
        comments: String,
        amount: Decimal,
        service: WalletService
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
            transactionStatus: nil, 
            nonceRaw: nil
        )
        
        service.core.coinStorage.append(transaction)
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
        return walletCore.validate(address: fixedAddress)
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
