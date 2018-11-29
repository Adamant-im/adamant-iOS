//
//  AdmWalletService+RichMessageProvider.swift
//  Adamant
//
//  Created by Anokhov Pavel on 27.09.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import MessageKit

extension AdmWalletService: RichMessageProvider {
    
    // MARK: Events
    
    /// Not supported yet
    func richMessageTapped(for transaction: RichMessageTransaction, at indexPath: IndexPath, in chat: ChatViewController) {
        return
    }
    
    func richMessageTapped(for transaction: TransferTransaction, at indexPath: IndexPath, in chat: ChatViewController) {
        guard let controller = router.get(scene: AdamantScene.Wallets.Adamant.transactionDetails) as? TransactionDetailsViewControllerBase else {
            fatalError("Can't get TransactionDetails scene")
        }
        
        controller.transaction = transaction
        controller.comment = transaction.comment
        
        if let address = accountService.account?.address {
            if address == transaction.senderId {
                controller.senderName = String.adamantLocalized.transactionDetails.yourAddress
            } else {
                controller.senderName = transaction.chatroom?.partner?.name
            }
            
            if address == transaction.recipientId {
                controller.recipientName = String.adamantLocalized.transactionDetails.yourAddress
            } else {
                controller.recipientName = transaction.chatroom?.partner?.name
            }
        }
        
        if let nav = chat.navigationController {
            nav.pushViewController(controller, animated: true)
        } else {
            chat.present(controller, animated: true, completion: nil)
        }
    }
    
    // MARK: Cells
    
    func cellSizeCalculator(for messagesCollectionViewFlowLayout: MessagesCollectionViewFlowLayout) -> CellSizeCalculator {
        let calculator = TransferMessageSizeCalculator(layout: messagesCollectionViewFlowLayout)
        calculator.font = UIFont.systemFont(ofSize: 24)
        return calculator
    }
    
    func cell(for message: MessageType, isFromCurrentSender: Bool, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UICollectionViewCell {
        guard case .custom(let raw) = message.kind, let richMessage = raw as? RichMessageTransfer else {
            fatalError("ADM service tried to render wrong message kind: \(message.kind)")
        }
        
        let cellIdentifier = isFromCurrentSender ? cellIdentifierSent : cellIdentifierReceived
        guard let cell = messagesCollectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as? TransferCollectionViewCell else {
            fatalError("Can't dequeue \(cellIdentifier) cell")
        }
        
        cell.currencyLogoImageView.image = AdmWalletService.currencyLogo
        cell.currencySymbolLabel.text = AdmWalletService.currencySymbol
        
        cell.amountLabel.text = AdamantBalanceFormat.full.format(richMessage.amount)
        cell.dateLabel.text = message.sentDate.humanizedDateTime(withWeekday: false)
        
        if let status = (message as? TransferTransaction)?.statusEnum {
            cell.transactionStatus = status.toTransactionStatus()
        } else {
            cell.transactionStatus = nil
        }
        
        cell.commentsLabel.text = richMessage.comments
        
        if cell.isAlignedRight != isFromCurrentSender {
            cell.isAlignedRight = isFromCurrentSender
        }
        
        return cell
    }
    
    // MARK: Short description
    private static var formatter: NumberFormatter = {
        return AdamantBalanceFormat.currencyFormatter(for: .full, currencySymbol: currencySymbol)
    }()
    
    func shortDescription(for transaction: RichMessageTransaction) -> NSAttributedString {
        guard let balance = transaction.amount as Decimal? else {
            return NSAttributedString(string: "")
        }
        
        return NSAttributedString(string: shortDescription(isOutgoing: transaction.isOutgoing, balance: balance))
    }
    
    /// For ADM transfers
    func shortDescription(for transaction: TransferTransaction) -> String {
        guard let balance = transaction.amount as Decimal? else {
            return ""
        }
        
        return shortDescription(isOutgoing: transaction.isOutgoing, balance: balance)
    }
    
    private func shortDescription(isOutgoing: Bool, balance: Decimal) -> String {
        if isOutgoing {
            return "⬅️  \(AdmWalletService.formatter.string(fromDecimal: balance)!)"
        } else {
            return "➡️  \(AdmWalletService.formatter.string(fromDecimal: balance)!)"
        }
    }
}

// MARK: - Tools
extension MessageStatus {
    func toTransactionStatus() -> TransactionStatus {
        switch self {
        case .pending: return TransactionStatus.updating
        case .delivered: return TransactionStatus.success
        case .failed: return TransactionStatus.failed
        }
    }
}
