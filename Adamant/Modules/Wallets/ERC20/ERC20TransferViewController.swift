//
//  ERC20TransferViewController.swift
//  Adamant
//
//  Created by Anton Boyarkin on 07/07/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import UIKit
import Eureka
import Web3Core
import CommonKit

final class ERC20TransferViewController: TransferViewControllerBase {
    
    // MARK: Properties
    
    private var skipValueChange: Bool = false
    private let prefix = "0x"
    
    override var feeBalanceFormatter: NumberFormatter {
        return AdamantBalanceFormat.currencyFormatter(for: .full, currencySymbol: EthWalletService.currencySymbol)
    }
    
    override var isNeedAddFee: Bool { false }
    
    // MARK: Send
    
    @MainActor
    override func sendFunds() {
        let comments: String
        if let row: TextAreaRow = form.rowBy(tag: BaseRows.comments.tag), let text = row.value {
            comments = text
        } else {
            comments = ""
        }
        
        guard let service = service as? ERC20WalletService, let recipient = recipientAddress, let amount = amount else {
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
        service: ERC20WalletService
    ) {
        let transaction = SimpleTransactionDetails(
            txId: hash,
            senderAddress: transaction.sender?.address ?? "",
            recipientAddress: recipient,
            isOutgoing: true
        )
        
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
            $0.cell.textField.setLineBreakMode()
            
            if let recipient = recipientAddress {
                let trimmed = recipient.components(separatedBy: TransferViewControllerBase.invalidCharacters).joined()
                $0.value = trimmed
            }
            
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
                    var trimmed = text.components(separatedBy: TransferViewControllerBase.invalidCharacters).joined()
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
        let networkSymbol = service?.tokenNetworkSymbol ?? "ERC20"
        return String.adamant.wallets.erc20.sendToken(service?.tokenSymbol ?? "ERC20") + " (\(networkSymbol))"
    }
    
    override func validateAmount(_ amount: Decimal, withFee: Bool = true) -> Bool {
        guard amount > 0 else {
            return false
        }
        
        guard let service = service,
              let balance = service.wallet?.balance
        else {
            return false
        }
        
        let minAmount = service.minAmount

        guard minAmount <= amount else {
            return false
        }
        
        let isEnoughBalance = balance >= amount
        let isEnoughFee = isEnoughFee()
        
        return isEnoughBalance && isEnoughFee
    }
    
    override func isEnoughFee() -> Bool {
        guard let service = service,
              let rootCoinBalance = rootCoinBalance,
              rootCoinBalance >= service.diplayTransactionFee,
              service.isTransactionFeeValid
        else {
            return false
        }
        return true
    }
}
