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
        
        // MARK: 2. Go go transaction
        Task {
            do {
                let transactionLisk = try await getTransaction(by: hash)
                dialogService.dismissProgress()
                
                presentDetailTransactionVC(hash: hash,
                                           senderName: senderName,
                                           recipientName: recipientName,
                                           comment: comment,
                                           senderAddress: transactionLisk.senderAddress,
                                           recipientAddress: transactionLisk.recipientAddress,
                                           transaction: transactionLisk,
                                           richTransaction: transaction,
                                           in: chat)
                
            } catch let error as ApiServiceError {
                guard case let .internalError(message, _) = error,
                      message.contains("does not exist")
                else {
                    dialogService.dismissProgress()
                    dialogService.showRichError(error: error)
                    return
                }
                
                do {
                    let senderAddress = try await getWalletAddress(byAdamantAddress: transaction.senderAddress)
                    let recipientAddress = try await getWalletAddress(byAdamantAddress: transaction.recipientAddress)
                    
                    dialogService.dismissProgress()
                    
                    presentDetailTransactionVC(hash: hash,
                                               senderName: senderName,
                                               recipientName: recipientName,
                                               comment: comment,
                                               senderAddress: senderAddress,
                                               recipientAddress: recipientAddress,
                                               transaction: nil,
                                               richTransaction: transaction,
                                               in: chat)
                } catch {
                    dialogService.dismissProgress()
                    dialogService.showRichError(error: error)
                }
            } catch {
                dialogService.dismissProgress()
                dialogService.showRichError(error: error)
            }
        }
    }
    
    private func presentDetailTransactionVC(hash: String,
                                            senderName: String?,
                                            recipientName: String?,
                                            comment: String?,
                                            senderAddress: String,
                                            recipientAddress: String,
                                            transaction: Transactions.TransactionModel?,
                                            richTransaction: RichMessageTransaction,
                                            in chat: ChatViewController) {
        guard let vc = router.get(scene: AdamantScene.Wallets.Lisk.transactionDetails) as? LskTransactionDetailsViewController else {
            dialogService.dismissProgress()
            return
        }
        
        vc.service = self
        vc.senderName = senderName
        vc.recipientName = recipientName
        vc.comment = comment
        
        let amount: Decimal
        if let amountRaw = richTransaction.richContent?[RichContentKeys.transfer.amount], let decimal = Decimal(string: amountRaw) {
            amount = decimal
        } else {
            amount = 0
        }
        
        let failedTransaction = SimpleTransactionDetails(txId: hash,
                                                         senderAddress: senderAddress,
                                                         recipientAddress: recipientAddress,
                                                         dateValue: nil,
                                                         amountValue: amount,
                                                         feeValue: nil,
                                                         confirmationsValue: nil,
                                                         blockValue: nil,
                                                         isOutgoing: richTransaction.isOutgoing,
                                                         transactionStatus: TransactionStatus.pending)

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
