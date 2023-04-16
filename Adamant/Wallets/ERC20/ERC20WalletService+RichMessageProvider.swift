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
            guard let vc = router.get(scene: AdamantScene.Wallets.ERC20.transactionDetails) as? ERC20TransactionDetailsViewController else {
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
                let amount: Decimal
                if let amountRaw = transaction.richContent?[RichContentKeys.transfer.amount], let decimal = Decimal(string: amountRaw) {
                    amount = decimal
                } else {
                    amount = 0
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
