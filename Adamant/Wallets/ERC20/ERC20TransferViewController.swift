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
    
    static let invalidCharacters: CharacterSet = {
        CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789").inverted
    }()

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
        if let detailsVc = router.get(scene: AdamantScene.Wallets.ERC20.transactionDetails) as? ERC20TransactionDetailsViewController {
            detailsVc.transaction = transaction
            detailsVc.service = service
            detailsVc.senderName = String.adamant.transactionDetails.yourAddress
            detailsVc.recipientName = recipientName
            
            if comments.count > 0 {
                detailsVc.comment = comments
            }
            
            delegate?.transferViewController(self, didFinishWithTransfer: transaction, detailsViewController: detailsVc)
        } else {
            delegate?.transferViewController(self, didFinishWithTransfer: transaction, detailsViewController: nil)
        }
    }
    
    // MARK: Overrides
    
    private var _recipient: String?
    
    override var recipientAddress: String? {
        set {
            _recipient = newValue?.validateEthAddress()
            
            if let row: TextRow = form.rowBy(tag: BaseRows.address.tag) {
                row.value = _recipient
                row.updateCell()
            }
        }
        get {
            return _recipient
        }
    }
    
    override func validateRecipient(_ address: String) -> AddressValidationResult {
        let fixedAddress = address.validateEthAddress()
        return service?.validate(address: fixedAddress) ?? .invalid(description: nil)
    }
    
    override func recipientRow() -> BaseRow {
        let row = TextRow {
            $0.tag = BaseRows.address.tag
            $0.cell.textField.placeholder = String.adamant.newChat.addressPlaceholder
            $0.cell.textField.keyboardType = UIKeyboardType.namePhonePad
            $0.cell.textField.autocorrectionType = .no
            $0.cell.textField.setLineBreakMode()
            
            if let recipient = recipientAddress {
                let trimmed = recipient.components(separatedBy: EthTransferViewController.invalidCharacters).joined()
                $0.value = trimmed
            }
            
            let prefix = UILabel()
            prefix.text = "0x"
            prefix.sizeToFit()
            
            let view = UIView()
            view.addSubview(prefix)
            view.frame = prefix.frame
            $0.cell.textField.leftView = view
            $0.cell.textField.leftViewMode = .always
            
            if recipientIsReadonly {
                $0.disabled = true
                prefix.textColor = UIColor.lightGray
            }
            }.cellUpdate { [weak self] (cell, _) in
                if let text = cell.textField.text {
                    cell.textField.text = text.components(separatedBy: EthTransferViewController.invalidCharacters).joined()
                    
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
                    var trimmed = text.components(separatedBy: EthTransferViewController.invalidCharacters).joined()
                    if trimmed.starts(with: "0x") {
                        let i = trimmed.index(trimmed.startIndex, offsetBy: 2)
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
