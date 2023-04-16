//
//  EthWalletService+RichMessageProvider.swift
//  Adamant
//
//  Created by Anokhov Pavel on 08.09.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import MessageKit
import UIKit

extension EthWalletService: RichMessageProvider {
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
            let hash = richContent[RichContentKeys.transfer.hash],
            let dialogService = dialogService else {
                return
        }
        
        dialogService.showProgress(withMessage: nil, userInteractionEnable: false)
        
        let comment: String?
        if let raw = transaction.richContent?[RichContentKeys.transfer.comments], raw.count > 0 {
            comment = raw
        } else {
            comment = nil
        }
        
        // MARK: 1. Sender & recipient names
        
        let senderName: String?
        let recipientName: String?
        
        if let address = accountService?.account?.address {
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
        
        // MARK: 2. Go to transaction
        
        Task {
            guard let vc = router.get(scene: AdamantScene.Wallets.Ethereum.transactionDetails) as? EthTransactionDetailsViewController else {
                return
            }
            
            vc.service = self
            vc.senderName = senderName
            vc.recipientName = recipientName
            vc.comment = comment
            
            do {
                let ethTransaction = try await getTransaction(by: hash)
                vc.transaction = ethTransaction
            } catch {
                var amount: Decimal = .zero
                
                if
                    let amountRaw = transaction.richContent?[RichContentKeys.transfer.amount],
                    let decimal = Decimal(string: amountRaw)
                {
                    amount = decimal
                }
                
                let failedTransaction = SimpleTransactionDetails(
                    txId: hash,
                    senderAddress: transaction.senderAddress,
                    recipientAddress: transaction.recipientAddress,
                    dateValue: nil,
                    amountValue: amount,
                    feeValue: nil,
                    confirmationsValue: nil,
                    blockValue: nil,
                    isOutgoing: transaction.isOutgoing,
                    transactionStatus: TransactionStatus.failed
                )
                
                vc.transaction = failedTransaction
            }
            
            dialogService.dismissProgress()
            
            chat.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    // MARK: Short description
    
    func shortDescription(for transaction: RichMessageTransaction) -> NSAttributedString {
        let amount: String
        
        guard let raw = transaction.richContent?[RichContentKeys.transfer.amount] else {
            return NSAttributedString(string: "⬅️  \(EthWalletService.currencySymbol)")
        }
        
        if let decimal = Decimal(string: raw) {
            amount = AdamantBalanceFormat.full.format(decimal)
        } else {
            amount = raw
        }
        
        let string: String
        if transaction.isOutgoing {
            string = "⬅️  \(amount) \(EthWalletService.currencySymbol)"
        } else {
            string = "➡️  \(amount) \(EthWalletService.currencySymbol)"
        }
        
        return NSAttributedString(string: string)
    }
}
