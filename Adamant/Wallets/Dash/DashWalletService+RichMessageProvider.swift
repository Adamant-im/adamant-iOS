//
//  DashWalletService+RichMessageProvider.swift
//  Adamant
//
//  Created by Anton Boyarkin on 26/05/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import Foundation
import MessageKit
import UIKit

extension DashWalletService: RichMessageProvider {
    
    var dynamicRichMessageType: String {
        return type(of: self).richMessageType
    }
    
    // MARK: Events
    
    @MainActor
    func richMessageTapped(for transaction: RichMessageTransaction, at indexPath: IndexPath, in chat: ChatViewController) {
        // MARK: 0. Prepare
        guard let richContent = transaction.richContent,
            let hash = richContent[RichContentKeys.transfer.hash],
            let dialogService = dialogService,
            let address = wallet?.address else {
                return
        }
        
        dialogService.showProgress(withMessage: nil, userInteractionEnable: false)
        
        let comment: String?
        if let raw = transaction.richContent?[RichContentKeys.transfer.comments], raw.count > 0 {
            comment = raw
        } else {
            comment = nil
        }
        
        let senderName: String?
        let recipientName: String?
        
        if let address = accountService.account?.address {
            if let senderId = transaction.senderId, senderId.caseInsensitiveCompare(address) == .orderedSame {
                senderName = String.adamantLocalized.transactionDetails.yourAddress
            } else {
                senderName = transaction.chatroom?.partner?.name
            }
            
            if let recipientId = transaction.recipientId, recipientId.caseInsensitiveCompare(address) == .orderedSame {
                recipientName = String.adamantLocalized.transactionDetails.yourAddress
            } else {
                recipientName = transaction.chatroom?.partner?.name
            }
        } else if let partner = transaction.chatroom?.partner, let id = partner.address {
            if transaction.senderId == id {
                senderName = partner.name
                recipientName = nil
            } else {
                recipientName = partner.name
                senderName = nil
            }
        } else {
            senderName = nil
            recipientName = nil
        }
        
        // MARK: Get transaction
        
        Task {
            do {
                let detailTransaction = try await getTransaction(by: hash)
                let blockId = try await getBlockId(by: detailTransaction.blockHash)
                
                presentDetailTransactionVC(hash: hash,
                                           senderName: senderName,
                                           recipientName: recipientName,
                                           comment: comment,
                                           address: address,
                                           blockId: blockId,
                                           transaction: detailTransaction,
                                           richTransaction: transaction,
                                           in: chat)
            } catch {
                dialogService.dismissProgress()
                
                guard let error = error as? WalletServiceError else { return }
                guard case let .internalError(message, _) = error,
                      message == "No transaction"
                else {
                    dialogService.showRichError(error: error)
                    return
                }
                
                presentDetailTransactionVC(hash: hash,
                                           senderName: senderName,
                                           recipientName: recipientName,
                                           comment: comment,
                                           address: address,
                                           blockId: nil,
                                           transaction: nil,
                                           richTransaction: transaction,
                                           in: chat)
            }
        }
    }
    
    private func presentDetailTransactionVC(hash: String,
                                            senderName: String?,
                                            recipientName: String?,
                                            comment: String?,
                                            address: String,
                                            blockId: String?,
                                            transaction: BTCRawTransaction?,
                                            richTransaction: RichMessageTransaction,
                                            in chat: ChatViewController) {
        guard let vc = router.get(scene: AdamantScene.Wallets.Dash.transactionDetails) as? DashTransactionDetailsViewController else {
            return
        }
        
        let amount: Decimal
        if let amountRaw = richTransaction.richContent?[RichContentKeys.transfer.amount], let decimal = Decimal(string: amountRaw) {
            amount = decimal
        } else {
            amount = 0
        }
        
        var dashTransaction = transaction?.asBtcTransaction(DashTransaction.self, for: address)
        if let blockId = blockId {
            dashTransaction = transaction?.asBtcTransaction(DashTransaction.self, for: address, blockId: blockId)
        }
        let failedTransaction = SimpleTransactionDetails(txId: hash,
                                                         senderAddress: richTransaction.senderAddress,
                                                         recipientAddress: richTransaction.recipientAddress,
                                                         dateValue: nil,
                                                         amountValue: amount,
                                                         feeValue: nil,
                                                         confirmationsValue: nil,
                                                         blockValue: nil,
                                                         isOutgoing: richTransaction.isOutgoing,
                                                         transactionStatus: TransactionStatus.failed)
        
        vc.service = self
        vc.senderName = senderName
        vc.recipientName = recipientName
        vc.comment = comment
        vc.transaction = dashTransaction ?? failedTransaction
        chat.navigationController?.pushViewController(vc, animated: true)
    }
    
    // MARK: Cells
    
    func cellSizeCalculator(for messagesCollectionViewFlowLayout: MessagesCollectionViewFlowLayout) -> CellSizeCalculator {
        let calculator = TransferMessageSizeCalculator(layout: messagesCollectionViewFlowLayout)
        calculator.font = UIFont.systemFont(ofSize: 24)
        return calculator
    }
    
    func cell(for message: MessageType, isFromCurrentSender: Bool, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UICollectionViewCell {
        guard case .custom(let raw) = message.kind, let transfer = raw as? RichMessageTransfer else {
            fatalError("DASH service tried to render wrong message kind: \(message.kind)")
        }
        
        let cellIdentifier = isFromCurrentSender ? cellIdentifierSent : cellIdentifierReceived
        guard let cell = messagesCollectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as? TransferCollectionViewCell else {
            fatalError("Can't dequeue \(cellIdentifier) cell")
        }
        
        cell.currencyLogoImageView.image = DashWalletService.currencyLogo
        cell.currencySymbolLabel.text = DashWalletService.currencySymbol
        
        cell.amountLabel.text = AdamantBalanceFormat.full.format(transfer.amount)
        cell.dateLabel.text = message.sentDate.humanizedDateTime(withWeekday: false)
        cell.transactionStatus = (message as? RichMessageTransaction)?.transactionStatus
        
        cell.commentsLabel.text = transfer.comments
        
        if cell.isAlignedRight != isFromCurrentSender {
            cell.isAlignedRight = isFromCurrentSender
        }
        
        cell.isFromCurrentSender = isFromCurrentSender
        
        return cell
    }
    
    // MARK: Short description
    
    private static var formatter: NumberFormatter = {
        return AdamantBalanceFormat.currencyFormatter(for: .full, currencySymbol: currencySymbol)
    }()
    
    func shortDescription(for transaction: RichMessageTransaction) -> NSAttributedString {
        let amount: String
        
        guard let raw = transaction.richContent?[RichContentKeys.transfer.amount] else {
            return NSAttributedString(string: "⬅️  \(DashWalletService.currencySymbol)")
        }
        
        if let decimal = Decimal(string: raw) {
            amount = AdamantBalanceFormat.full.format(decimal)
        } else {
            amount = raw
        }
        
        let string: String
        if transaction.isOutgoing {
            string = "⬅️  \(amount) \(DashWalletService.currencySymbol)"
        } else {
            string = "➡️  \(amount) \(DashWalletService.currencySymbol)"
        }
        
        return NSAttributedString(string: string)
    }
}
