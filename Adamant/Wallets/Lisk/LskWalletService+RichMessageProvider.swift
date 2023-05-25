//
//  LskWalletService+RichMessageProvider.swift
//  Adamant
//
//  Created by Anton Boyarkin on 06/12/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import MessageKit
import UIKit
import LiskKit

extension LskWalletService: RichMessageProvider {
    var newPendingInterval: TimeInterval {
        .init(milliseconds: type(of: self).newPendingInterval)
    }
    
    var oldPendingInterval: TimeInterval {
        .init(milliseconds: type(of: self).oldPendingInterval)
    }
    
    var registeredInterval: TimeInterval {
        .init(milliseconds: type(of: self).registeredInterval)
    }
    
    var newPendingAttempts: Int {
        type(of: self).newPendingAttempts
    }
    
    var oldPendingAttempts: Int {
        type(of: self).oldPendingAttempts
    }
    
    var dynamicRichMessageType: String {
        return type(of: self).richMessageType
    }
    
    // MARK: Events
    
    @MainActor
    func richMessageTapped(for transaction: RichMessageTransaction, in chat: ChatViewController) {
        // MARK: 0. Prepare
        guard let richContent = transaction.richContent,
              let hash = richContent[RichContentKeys.transfer.hash]
        else {
            return
        }
        
        let comment: String?
        if let raw = transaction.richContent?[RichContentKeys.transfer.comments], raw.count > 0 {
            comment = raw
        } else {
            comment = nil
        }
        
        // MARK: Go to transaction
        
        presentDetailTransactionVC(
            hash: hash,
            senderId: transaction.senderId,
            recipientId: transaction.recipientId,
            comment: comment,
            senderAddress: "",
            recipientAddress: "",
            transaction: nil,
            richTransaction: transaction,
            in: chat
        )
    }
    
    private func presentDetailTransactionVC(
        hash: String,
        senderId: String?,
        recipientId: String?,
        comment: String?,
        senderAddress: String,
        recipientAddress: String,
        transaction: Transactions.TransactionModel?,
        richTransaction: RichMessageTransaction,
        in chat: ChatViewController
    ) {
        guard let vc = router.get(scene: AdamantScene.Wallets.Lisk.transactionDetails) as? LskTransactionDetailsViewController else {
            dialogService.dismissProgress()
            return
        }
        
        vc.service = self
        vc.senderId = senderId
        vc.recipientId = recipientId
        vc.comment = comment
        
        let amount: Decimal
        if let amountRaw = richTransaction.richContent?[RichContentKeys.transfer.amount], let decimal = Decimal(string: amountRaw) {
            amount = decimal
        } else {
            amount = 0
        }
        
        let failedTransaction = SimpleTransactionDetails(
            txId: hash,
            senderAddress: senderAddress,
            recipientAddress: recipientAddress,
            dateValue: nil,
            amountValue: amount,
            feeValue: nil,
            confirmationsValue: nil,
            blockValue: nil,
            isOutgoing: richTransaction.isOutgoing,
            transactionStatus: nil)

        vc.transaction = transaction ?? failedTransaction
        chat.navigationController?.pushViewController(vc, animated: true)
    }
    
    // MARK: Short description
    
    func shortDescription(for transaction: RichMessageTransaction) -> NSAttributedString {
        let amount: String
        
        guard let raw = transaction.richContent?[RichContentKeys.transfer.amount] else {
            return NSAttributedString(string: "⬅️  \(LskWalletService.currencySymbol)")
        }
        
        if let decimal = Decimal(string: raw) {
            amount = AdamantBalanceFormat.full.format(decimal)
        } else {
            amount = raw
        }
        
        let string: String
        if transaction.isOutgoing {
            string = "⬅️  \(amount) \(LskWalletService.currencySymbol)"
        } else {
            string = "➡️  \(amount) \(LskWalletService.currencySymbol)"
        }
        
        return NSAttributedString(string: string)
    }
}
