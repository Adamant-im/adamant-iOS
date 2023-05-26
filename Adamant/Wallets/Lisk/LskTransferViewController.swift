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

final class LskTransferViewController: TransferViewControllerBase {
    
    // MARK: Dependencies
    
    private let chatsProvider: ChatsProvider
    
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
    
    init(
        accountService: AccountService,
        accountsProvider: AccountsProvider,
        dialogService: DialogService,
        router: Router,
        currencyInfoService: CurrencyInfoService,
        increaseFeeService: IncreaseFeeService,
        chatsProvider: ChatsProvider
    ) {
        self.chatsProvider = chatsProvider
        
        super.init(
            accountService: accountService,
            accountsProvider: accountsProvider,
            dialogService: dialogService,
            router: router,
            currencyInfoService: currencyInfoService,
            increaseFeeService: increaseFeeService
        )
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
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
        
        dialogService.showProgress(withMessage: String.adamantLocalized.transfer.transferProcessingMessage, userInteractionEnable: false)
        
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
                        try await service.sendTransaction(transaction)
                    } catch {
                        dialogService.showRichError(error: error)
                    }
                    
                    await service.update()
                }
                
                dialogService.dismissProgress()
                dialogService.showSuccess(withMessage: String.adamantLocalized.transfer.transferSuccess)
                
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
        if let detailsVc = router.get(scene: AdamantScene.Wallets.Lisk.transactionDetails) as? LskTransactionDetailsViewController {
            var transaction: TransactionEntity = transaction
            transaction.id = transactionId
            detailsVc.transaction = transaction
            detailsVc.service = service
            detailsVc.senderName = String.adamantLocalized.transactionDetails.yourAddress
            detailsVc.recipientName = recipientName
            
            if comments.count > 0 {
                detailsVc.comment = comments
            }
            
            delegate?.transferViewController(
                self,
                didFinishWithTransfer: transaction,
                detailsViewController: detailsVc
            )
        } else {
            delegate?.transferViewController(
                self,
                didFinishWithTransfer: transaction,
                detailsViewController: nil
            )
        }
    }
    
    // MARK: Overrides
    
    private var _recipient: String?
    
    override var recipientAddress: String? {
        set {
            _recipient = newValue
            
            if let row: RowOf<String> = form.rowBy(tag: BaseRows.address.tag) {
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
        
        switch service.validate(address: address) {
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
            $0.cell.textField.keyboardType = UIKeyboardType.alphabet
            $0.cell.textField.autocorrectionType = .no
            $0.cell.textField.setLineBreakMode()
            
            if let recipient = recipientAddress {
                $0.value = recipient
            }

            if recipientIsReadonly {
                $0.disabled = true
                $0.cell.textField.isEnabled = false
            }
        }.onChange { [weak self] row in
            if let text = row.value {
                self?._recipient = text
            }
            self?.updateToolbar(for: row)
        }.onCellSelection { [weak self] (cell, _) in
            self?.shareValue(self?.recipientAddress, from: cell)
        }

        return row
    }
    
    func reportTransferTo(
        admAddress: String,
        amount: Decimal,
        comments: String,
        hash: String
    ) async throws {
        let payload = RichMessageTransfer(type: LskWalletService.richMessageType, amount: amount, hash: hash, comments: comments)
        
        let message = AdamantMessage.richMessage(payload: payload)
       
        chatsProvider.removeChatPositon(for: admAddress)
        _ = try await chatsProvider.sendMessage(message, recipientId: admAddress)
    }
    
    override func defaultSceneTitle() -> String? {
        return String.adamantLocalized.sendLsk
    }
}
