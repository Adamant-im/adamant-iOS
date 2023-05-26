//
//  ERC20WalletService+RichMessageProvider.swift
//  Adamant
//
//  Created by Anton Boyarkin on 06/07/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import Foundation
import MessageKit
import UIKit

extension ERC20WalletService: RichMessageProvider {
    var newPendingInterval: TimeInterval {
        .init(milliseconds: EthWalletService.newPendingInterval)
    }
    
    var oldPendingInterval: TimeInterval {
        .init(milliseconds: EthWalletService.oldPendingInterval)
    }
    
    var registeredInterval: TimeInterval {
        .init(milliseconds: EthWalletService.registeredInterval)
    }
    
    var newPendingAttempts: Int {
        EthWalletService.newPendingAttempts
    }
    
    var oldPendingAttempts: Int {
        EthWalletService.oldPendingAttempts
    }
    
    // MARK: Events
    
    @MainActor
    func richMessageTapped(for transaction: RichMessageTransaction, in chat: ChatViewController) {
        // MARK: 0. Prepare
        guard let hash = transaction.getRichValue(for: RichContentKeys.transfer.hash)
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
        transaction: EthTransaction?,
        richTransaction: RichMessageTransaction,
        in chat: ChatViewController
    ) {
        guard let vc = router.get(scene: AdamantScene.Wallets.ERC20.transactionDetails) as? ERC20TransactionDetailsViewController else {
            return
        }
        
        let amount: Decimal
        if let amountRaw = richTransaction.getRichValue(for: RichContentKeys.transfer.amount),
           let decimal = Decimal(string: amountRaw) {
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
            transactionStatus: nil
        )
        
        vc.service = self
        vc.senderId = senderId
        vc.recipientId = recipientId
        vc.comment = comment
        vc.transaction = transaction ?? failedTransaction
        vc.richTransaction = richTransaction
        
        chat.navigationController?.pushViewController(vc, animated: true)
    }
    
    // MARK: Short description

    func shortDescription(for transaction: RichMessageTransaction) -> NSAttributedString {
        let amount: String
        
        guard let raw = transaction.getRichValue(for: RichContentKeys.transfer.amount)
        else {
            return NSAttributedString(string: "⬅️  \(self.tokenSymbol)")
        }
        
        if let decimal = Decimal(string: raw) {
            amount = AdamantBalanceFormat.full.format(decimal)
        } else {
            amount = raw
        }
        
        let string: String
        if transaction.isOutgoing {
            string = "⬅️  \(amount) \(self.tokenSymbol)"
        } else {
            string = "➡️  \(amount) \(self.tokenSymbol)"
        }
        
        return NSAttributedString(string: string)
    }
}
