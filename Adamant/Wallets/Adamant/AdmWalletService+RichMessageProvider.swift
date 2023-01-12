//
//  AdmWalletService+RichMessageProvider.swift
//  Adamant
//
//  Created by Anokhov Pavel on 27.09.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import MessageKit
import UIKit

extension AdmWalletService: RichMessageProvider {
    
    var dynamicRichMessageType: String {
        return type(of: self).richMessageType
    }
    
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
        
        if let address = accountService?.account?.address {
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
            controller.modalPresentationStyle = .overFullScreen
            chat.present(controller, animated: true, completion: nil)
        }
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
            return "⬅️  \(AdmWalletService.formatter.string(from: balance)!)"
        } else {
            return "➡️  \(AdmWalletService.formatter.string(from: balance)!)"
        }
    }
}

// MARK: - Tools
extension MessageStatus {
    func toTransactionStatus() -> TransactionStatus {
        switch self {
        case .pending: return TransactionStatus.pending
        case .delivered: return TransactionStatus.success
        case .failed: return TransactionStatus.failed
        }
    }
}
