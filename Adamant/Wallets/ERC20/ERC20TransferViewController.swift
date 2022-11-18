//
//  ERC20TransferViewController.swift
//  Adamant
//
//  Created by Anton Boyarkin on 07/07/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import UIKit
import Eureka

class ERC20TransferViewController: TransferViewControllerBase {
    
    // MARK: Dependencies
    
    var chatsProvider: ChatsProvider!
    
    // MARK: Properties
    
    private var skipValueChange: Bool = false
    
    static let invalidCharacters: CharacterSet = {
        CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789").inverted
    }()

    override var feeBalanceFormatter: NumberFormatter {
        return AdamantBalanceFormat.currencyFormatter(for: .full, currencySymbol: EthWalletService.currencySymbol)
    }
    
    // MARK: Send
    
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
        
        guard let dialogService = dialogService else {
            return
        }
        
        dialogService.showProgress(withMessage: String.adamantLocalized.transfer.transferProcessingMessage, userInteractionEnable: false)
        
        service.createTransaction(recipient: recipient, amount: amount) { [weak self] result in
            guard let vc = self else {
                dialogService.dismissProgress()
                dialogService.showError(withMessage: String.adamantLocalized.sharedErrors.unknownError, error: nil)
                return
            }

            switch result {
            case .success(let transaction):
                // MARK: 1. Send adm report
                if let reportRecipient = vc.admReportRecipient, let hash = transaction.txHash {
                    self?.reportTransferTo(admAddress: reportRecipient, amount: amount, comments: comments, hash: hash)
                }

                // MARK: 2. Send eth transaction
                service.sendTransaction(transaction) { result in
                    switch result {
                    case .success(let hash):
                        service.update()
                        vc.dialogService.showSuccess(withMessage: String.adamantLocalized.transfer.transferSuccess)
                        let transaction = SimpleTransactionDetails(txId: hash, senderAddress: transaction.sender?.address ?? "", recipientAddress: recipient, isOutgoing: true)
                        DispatchQueue.main.async {
                            if let detailsVc = vc.router.get(scene: AdamantScene.Wallets.ERC20.transactionDetails) as? ERC20TransactionDetailsViewController {
                                detailsVc.transaction = transaction
                                detailsVc.service = service
                                detailsVc.senderName = String.adamantLocalized.transactionDetails.yourAddress
                                detailsVc.recipientName = self?.recipientName

                                if comments.count > 0 {
                                    detailsVc.comment = comments
                                }

                                vc.delegate?.transferViewController(vc, didFinishWithTransfer: transaction, detailsViewController: detailsVc)
                            } else {
                                vc.delegate?.transferViewController(vc, didFinishWithTransfer: transaction, detailsViewController: nil)
                            }
                        }
                    case .failure(let error):
                        vc.dialogService.showRichError(error: error)
                    }
                }

            case .failure(let error):
                dialogService.dismissProgress()
                dialogService.showRichError(error: error)
            }
        }
    }
    
    // MARK: Overrides
    
    private var _recipient: String?
    
    override var recipientAddress: String? {
        set {
            if let recipient = newValue, let first = recipient.first, first != "0" {
                _recipient = "0x\(recipient)"
            } else {
                _recipient = newValue
            }
            
            if let row: TextRow = form.rowBy(tag: BaseRows.address.tag) {
                row.value = _recipient
                row.updateCell()
            }
        }
        get {
            return _recipient
        }
    }
    
    override func validateRecipient(_ address: String) -> Bool {
        guard let service = service else {
            return false
        }
        
        let fixedAddress: String
        if let first = address.first, first != "0" {
            fixedAddress = "0x\(address)"
        } else {
            fixedAddress = address
        }
        
        switch service.validate(address: fixedAddress) {
        case .valid:
            return true
            
        case .invalid, .system:
            return false
        }
    }
    
    override func recipientRow() -> BaseRow {
        let row = TextRow {
            $0.tag = BaseRows.address.tag
            $0.cell.textField.placeholder = String.adamantLocalized.newChat.addressPlaceholder
            $0.cell.textField.keyboardType = UIKeyboardType.namePhonePad
            $0.cell.textField.autocorrectionType = .no
            
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
        }.onCellSelection { [weak self] (cell, _) in
            self?.shareValue(self?.recipientAddress, from: cell)
        }
        
        return row
    }
    
    override func handleRawAddress(_ address: String) -> Bool {
        guard let service = service else {
            return false
        }
        
        let parsedAddress: String
        if address.hasPrefix("ethereum:"), let firstIndex = address.firstIndex(of: ":") {
            let index = address.index(firstIndex, offsetBy: 1)
            parsedAddress = String(address[index...])
        } else {
            parsedAddress = address
        }
        
        switch service.validate(address: parsedAddress) {
        case .valid:
            if let row: TextRow = form.rowBy(tag: BaseRows.address.tag) {
                row.value = parsedAddress
                row.updateCell()
            }
            
            return true
            
        default:
            return false
        }
    }
    
    func reportTransferTo(admAddress: String, amount: Decimal, comments: String, hash: String) {
        guard let type = (self.service as? RichMessageProvider)?.dynamicRichMessageType else {
            return
        }
        let payload = RichMessageTransfer(type: type, amount: amount, hash: hash, comments: comments)
        
        let message = AdamantMessage.richMessage(payload: payload)
        
        chatsProvider.sendMessage(message, recipientId: admAddress) { [weak self] result in
            if case .failure(let error) = result {
                self?.dialogService.showRichError(error: error)
            }
        }
    }
    
    override func defaultSceneTitle() -> String? {
        let networkSymbol = service?.tokenNetworkSymbol ?? "ERC20"
        return String.adamantLocalized.wallets.erc20.sendToken(service?.tokenSymbol ?? "ERC20") + " (\(networkSymbol))"
    }
    
    override func validateAmount(_ amount: Decimal, withFee: Bool = true) -> Bool {
        guard amount > 0 else {
            return false
        }
        
        guard let service = service,
              let balance = service.wallet?.balance,
              let minAmount = service.wallet?.minAmount
        else {
            return false
        }
        
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
