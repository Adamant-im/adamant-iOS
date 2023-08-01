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
import CommonKit

extension DashWalletService: RichMessageProvider {
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
        guard let hash = transaction.getRichValue(for: RichContentKeys.transfer.hash),
              let address = accountService.account?.address
        else {
            return
        }
                
        let comment: String?
        if let raw = transaction.getRichValue(for: RichContentKeys.transfer.comments), raw.count > 0 {
            comment = raw
        } else {
            comment = nil
        }
        
        // MARK: Go to transaction
        
        presentDetailTransactionVC(
            hash: hash,
            senderId: transaction.senderId,
            recipientId: transaction.recipientId,
            senderAddress: "",
            recipientAddress: "",
            comment: comment,
            address: address,
            blockId: nil,
            transaction: nil,
            richTransaction: transaction,
            in: chat
        )
    }
    
    private func presentDetailTransactionVC(
        hash: String,
        senderId: String?,
        recipientId: String?,
        senderAddress: String,
        recipientAddress: String,
        comment: String?,
        address: String,
        blockId: String?,
        transaction: BTCRawTransaction?,
        richTransaction: RichMessageTransaction,
        in chat: ChatViewController
    ) {
        guard let vc = router.get(scene: AdamantScene.Wallets.Dash.transactionDetails) as? DashTransactionDetailsViewController else {
            return
        }
        
        let amount: Decimal
        if let amountRaw = richTransaction.getRichValue(for: RichContentKeys.transfer.amount),
           let decimal = Decimal(string: amountRaw) {
            amount = decimal
        } else {
            amount = 0
        }
        
        var dashTransaction = transaction?.asBtcTransaction(DashTransaction.self, for: address)
        if let blockId = blockId {
            dashTransaction = transaction?.asBtcTransaction(DashTransaction.self, for: address, blockId: blockId)
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
            transactionStatus: nil
        )
        
        vc.service = self
        vc.senderId = senderId
        vc.recipientId = recipientId
        vc.comment = comment
        vc.transaction = dashTransaction ?? failedTransaction
        vc.richTransaction = richTransaction
        
        chat.navigationController?.pushViewController(vc, animated: true)
    }
    
    // MARK: Short description
    
    func shortDescription(for transaction: RichMessageTransaction) -> NSAttributedString {
        let amount: String
        
        guard let raw = transaction.getRichValue(for: RichContentKeys.transfer.amount)
        else {
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
