//
//  BtcTransferViewController.swift
//  Adamant
//
//  Created by Anton Boyarkin on 08/02/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import UIKit
import Eureka

class BtcTransferViewController: TransferViewControllerBase {
    
    // MARK: Dependencies
    
    var chatsProvider: ChatsProvider
    
    // MARK: Properties
    
    override var balanceFormatter: NumberFormatter {
        if let service = service {
            return AdamantBalanceFormat.currencyFormatter(for: .full, currencySymbol: type(of: service).currencySymbol)
        } else {
            return AdamantBalanceFormat.currencyFormatterFull
        }
    }
    
    private var skipValueChange: Bool = false
    
    static let invalidCharacters: CharacterSet = CharacterSet.decimalDigits.inverted
    
    // MARK: - Init
    
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
        
        guard let service = service as? BtcWalletService, let recipient = recipientAddress, let amount = amount else {
            return
        }
        
        dialogService.showProgress(withMessage: String.adamantLocalized.transfer.transferProcessingMessage, userInteractionEnable: false)
        
        Task {
            do {
                let transaction = try await service.createTransaction(recipient: recipient, amount: amount)
                
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
                    try await service.sendTransaction(transaction)
                    try await service.update()
                }
                
                var detailTransaction: BtcTransaction?
                if let hash = transaction.txHash {
                    detailTransaction = try? await service.getTransaction(by: hash)
                }
                
                processTransaction(
                    self,
                    localTransaction: detailTransaction,
                    service: service,
                    comments: comments,
                    transaction: transaction
                )
                
                dialogService.dismissProgress()
                dialogService.showSuccess(withMessage: String.adamantLocalized.transfer.transferSuccess)
            } catch {
                dialogService.dismissProgress()
                dialogService.showRichError(error: error)
            }
        }
    }
    
    private func processTransaction(
        _ vc: BtcTransferViewController,
        localTransaction: BtcTransaction?,
        service: BtcWalletService,
        comments: String,
        transaction: TransactionDetails
    ) {
        vc.dialogService.showSuccess(withMessage: String.adamantLocalized.transfer.transferSuccess)
        
        if let detailsVc = vc.router.get(scene: AdamantScene.Wallets.Bitcoin.transactionDetails) as? BtcTransactionDetailsViewController {
            detailsVc.transaction = localTransaction ?? transaction
            detailsVc.service = service
            detailsVc.senderName = String.adamantLocalized.transactionDetails.yourAddress
            
            if recipientAddress == service.wallet?.address {
                detailsVc.recipientName = String.adamantLocalized.transactionDetails.yourAddress
            } else {
                detailsVc.recipientName = self.recipientName
            }
            
            if comments.count > 0 {
                detailsVc.comment = comments
            }
            
            vc.delegate?.transferViewController(vc, didFinishWithTransfer: transaction, detailsViewController: detailsVc)
        } else {
            vc.delegate?.transferViewController(vc, didFinishWithTransfer: transaction, detailsViewController: nil)
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
            $0.cell.textField.setLineBreakMode()
            
            if let recipient = recipientAddress {
                $0.value = recipient
            }
            
            if recipientIsReadonly {
                $0.disabled = true
            }
        }.onChange { [weak self] row in
            if let text = row.value {
                self?._recipient = text
            }

            if let skip = self?.skipValueChange, skip {
                self?.skipValueChange = false
                return
            }
            self?.updateToolbar(for: row)
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
        if address.hasPrefix("bitcoin:"), let firstIndex = address.firstIndex(of: ":") {
            let index = address.index(firstIndex, offsetBy: 1)
            parsedAddress = String(address[index...])
        } else {
            parsedAddress = address
        }
        
        switch service.validate(address: parsedAddress) {
        case .valid:
            if let row: RowOf<String> = form.rowBy(tag: BaseRows.address.tag) {
                row.value = parsedAddress
                row.updateCell()
            }
            
            return true
            
        default:
            return false
        }
    }
    
    func reportTransferTo(
        admAddress: String,
        amount: Decimal,
        comments: String,
        hash: String
    ) async throws {
        let payload = RichMessageTransfer(type: BtcWalletService.richMessageType, amount: amount, hash: hash, comments: comments)
        
        let message = AdamantMessage.richMessage(payload: payload)
        
        _ = try await chatsProvider.sendMessage(message, recipientId: admAddress)
    }
    
    override func defaultSceneTitle() -> String? {
        return String.adamantLocalized.sendBtc
    }
}
