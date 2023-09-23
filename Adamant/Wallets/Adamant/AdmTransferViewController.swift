//
//  AdmTransferViewController.swift
//  Adamant
//
//  Created by Anokhov Pavel on 18.08.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import Eureka
import SafariServices
import CommonKit

// MARK: - Localization
extension String.adamant {
    enum transferAdm {
        static func accountNotFoundAlertTitle(for address: String) -> String {
            return String.localizedStringWithFormat(.localized("TransferScene.unsafeTransferAlert.title", comment: "Transfer: Alert title: Account not found or not initiated. Alert user that he still can send money, but need to double ckeck address"), address)
        }
            
        static let accountNotFoundAlertBody = String.localized("TransferScene.unsafeTransferAlert.body", comment: "Transfer: Alert body: Account not found or not initiated. Alert user that he still can send money, but need to double ckeck address")
        
        static let accountNotFoundChatAlertBody = String.localized("TransferScene.unsafeChatAlert.body", comment: "Transfer: Alert body: Account is not initiated. It's not possible to start a chat, as the Blockchain doesn't store the account's public key to encrypt messages.")
    }
}

final class AdmTransferViewController: TransferViewControllerBase {
    // MARK: Properties
    
    private var skipValueChange: Bool = false
    
    static let invalidCharactersSet = CharacterSet.decimalDigits.inverted
    
    // MARK: Sending
    
    @MainActor
    override func sendFunds() {
        guard let service = service as? AdmWalletService, let recipient = recipientAddress, let amount = amount else {
            return
        }
        
        let comments: String
        if let row: TextAreaRow = form.rowBy(tag: BaseRows.comments.tag), let text = row.value {
            comments = text
        } else {
            comments = ""
        }
        
        dialogService.showProgress(withMessage: String.adamant.transfer.transferProcessingMessage, userInteractionEnable: false)
        
        // Check recipient
        Task {
            do {
                let account = try await accountsProvider.getAccount(byAddress: recipient)
                
                guard !account.isDummy else {
                    throw AccountsProviderError.dummy(account)
                }
                
                sendFundsInternal(
                    service: service,
                    recipient: recipient,
                    amount: amount,
                    comments: comments
                )
            } catch let error as AccountsProviderError {
                switch error {
                case .notFound, .notInitiated, .dummy:
                    self.dialogService.dismissProgress()
                    
                    dialogService.presentDummyAlert(
                        for: recipient,
                        from: view,
                        canSend: true
                    ) { [weak self] _ in
                        self?.dialogService.showProgress(
                            withMessage: String.adamant.transfer.transferProcessingMessage,
                            userInteractionEnable: false
                        )
                        
                        self?.sendFundsInternal(
                            service: service,
                            recipient: recipient,
                            amount: amount,
                            comments: comments
                        )
                    }
                case .invalidAddress, .serverError, .networkError:
                    self.dialogService.showWarning(withMessage: error.localized)
                }
            } catch {
                self.dialogService.showWarning(withMessage: error.localizedDescription)
            }
        }
    }
    
    @MainActor
    private func sendFundsInternal(
        service: AdmWalletService,
        recipient: String,
        amount: Decimal,
        comments: String
    ) {
        Task {
            do {
                let result = try await service.sendMoney(
                    recipient: recipient,
                    amount: amount,
                    comments: comments,
                    replyToMessageId: replyToMessageId
                )
                
                service.update()
                dialogService.dismissProgress()
                
                dialogService.showSuccess(withMessage: String.adamant.transfer.transferSuccess)
                
                openDetailVC(
                    result: result,
                    vc: self,
                    recipient: recipient,
                    comments: comments
                )
            } catch {
                dialogService.dismissProgress()
                dialogService.showRichError(error: error)
            }
        }
    }
    
    private func openDetailVC(result: TransactionDetails, vc: AdmTransferViewController, recipient: String, comments: String) {
        let detailsVC = router.get(scene: AdamantScene.Wallets.Adamant.transactionDetails) as? AdmTransactionDetailsViewController
        detailsVC?.transaction = result
        
        if comments.count > 0 {
            detailsVC?.comment = comments
        }
        
        // MARK: Sender, you
        detailsVC?.senderName = String.adamant.transactionDetails.yourAddress
        
        // MARK: Get recipient
        if let recipientName = recipientName {
            detailsVC?.recipientName = recipientName
            vc.delegate?.transferViewController(vc, didFinishWithTransfer: result, detailsViewController: detailsVC)
        } else {
            Task {
                do {
                    let account = try await accountsProvider.getAccount(byAddress: recipient)
                    detailsVC?.recipientName = account.name
                    vc.delegate?.transferViewController(vc, didFinishWithTransfer: result, detailsViewController: detailsVC)
                } catch {
                    vc.delegate?.transferViewController(vc, didFinishWithTransfer: result, detailsViewController: detailsVC)
                }
            }
        }
    }
    
    // MARK: Overrides
    
    override var recipientAddress: String? {
        set {
            let _recipient: String?
            if let recipient = newValue, let first = recipient.first, first != "U" {
                _recipient = "U\(recipient)"
            } else {
                _recipient = newValue
            }
            
            if let row: TextRow = form.rowBy(tag: BaseRows.address.tag) {
                row.value = _recipient
                row.updateCell()
            }
        }
        get {
            let recipient: String? = form.rowBy(tag: BaseRows.address.tag)?.value
            guard let recipient = recipient,
                  let first = recipient.first,
                  first != "U"
            else {
                return recipient
            }
            
            return "U\(recipient)"
        }
    }
    
    override func recipientRow() -> BaseRow {
        let row = TextRow {
            $0.tag = BaseRows.address.tag
            $0.cell.textField.placeholder = String.adamant.newChat.addressPlaceholder
            $0.cell.textField.setPopupKeyboardType(.numberPad)
            $0.cell.textField.setLineBreakMode()
            
            if let recipient = recipientAddress {
                let trimmed = recipient.components(separatedBy: AdmTransferViewController.invalidCharactersSet).joined()
                $0.value = trimmed
            }
            
            let prefix = UILabel()
            prefix.text = "U"
            prefix.sizeToFit()
            
            let view = UIView()
            view.addSubview(prefix)
            view.frame = prefix.frame
            $0.cell.textField.leftView = view
            $0.cell.textField.leftViewMode = .always
            $0.cell.textField.autocorrectionType = .no
            if recipientIsReadonly {
                $0.disabled = true
                prefix.textColor = UIColor.lightGray
            }
        }.cellUpdate { [weak self] cell, _ in
            if let text = cell.textField.text {
                cell.textField.text = text.components(separatedBy: AdmTransferViewController.invalidCharactersSet).joined()

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
                var trimmed = ""
                if let admAddress = text.getAdamantAddress() {
                    trimmed = admAddress.address.components(separatedBy: AdmTransferViewController.invalidCharactersSet).joined()
                } else if let admAddress = text.getLegacyAdamantAddress() {
                    trimmed = admAddress.address.components(separatedBy: AdmTransferViewController.invalidCharactersSet).joined()
                } else {
                    trimmed = text.components(separatedBy: AdmTransferViewController.invalidCharactersSet).joined()
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
    
    override func validateRecipient(_ address: String) -> AddressValidationResult {
        let fixedAddress: String
        if let first = address.first, first != "U" {
            fixedAddress = "U\(address)"
        } else {
            fixedAddress = address
        }
        
        switch AdamantUtilities.validateAdamantAddress(address: fixedAddress) {
        case .valid:
            return .valid
            
        case .system, .invalid:
            return .invalid(description: nil)
        }
    }
    
    override func handleRawAddress(_ address: String) -> Bool {
        if let admAddress = address.getAdamantAddress() {
            recipientAddress = admAddress.address
            
            if let row: SafeDecimalRow = form.rowBy(tag: BaseRows.amount.tag) {
                row.value = admAddress.amount
                row.updateCell()
                reloadFormData()
            }
            return true
        } else if let admAddress = address.getLegacyAdamantAddress() {
            recipientAddress = admAddress.address
            return true
        }
        
        return false
    }
    
    override func defaultSceneTitle() -> String? {
        return String.adamant.wallets.sendAdm
    }
    
}
