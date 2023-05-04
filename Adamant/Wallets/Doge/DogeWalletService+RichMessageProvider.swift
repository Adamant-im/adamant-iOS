//
//  DogeWalletService+RichMessageProvider.swift
//  Adamant
//
//  Created by Anton Boyarkin on 13/03/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import Foundation
import MessageKit
import UIKit

extension DogeWalletService: RichMessageProvider {
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
              let dialogService = dialogService,
              let address = wallet?.address
        else {
            return
        }
        
        dialogService.showProgress(withMessage: nil, userInteractionEnable: false)
        
        let comment: String?
        if let raw = transaction.getRichValue(for: RichContentKeys.transfer.comments), raw.count > 0 {
            comment = raw
        } else {
            comment = nil
        }
        
        // MARK: Get transaction
        guard let vc = router.get(scene: AdamantScene.Wallets.Doge.transactionDetails) as? DogeTransactionDetailsViewController
        else {
            return
        }
        
        // MARK: Prepare details view controller
        vc.service = self
        vc.comment = comment
        
        Task {
            do {
                let dogeRawTransaction = try await getTransaction(by: hash)
                let dogeTransaction = dogeRawTransaction.asBtcTransaction(DogeTransaction.self, for: address)
                
                // MARK: Self name
                if dogeTransaction.senderAddress == address {
                    vc.senderName = String.adamantLocalized.transactionDetails.yourAddress
                }
                if dogeTransaction.recipientAddress == address {
                    vc.recipientName = String.adamantLocalized.transactionDetails.yourAddress
                }
                
                vc.transaction = dogeTransaction
                
                // MARK: Get partner name async
                if let partner = transaction.partner,
                   let partnerAddress = partner.address,
                   let partnerName = partner.name,
                   let address = try? await getWalletAddress(byAdamantAddress: partnerAddress) {
                    if dogeTransaction.senderAddress == address {
                        vc.senderName = partnerName
                    }
                    if dogeTransaction.recipientAddress == address {
                        vc.recipientName = partnerName
                    }
                }
                
                // MARK: Get block id async
                if let blockHash = dogeRawTransaction.blockHash,
                   let id = try? await getBlockId(by: blockHash) {
                    vc.transaction = dogeRawTransaction.asBtcTransaction(DogeTransaction.self, for: address, blockId: id)
                }
                
                dialogService.dismissProgress()
                chat.navigationController?.pushViewController(vc, animated: true)
                
            } catch {
                let amount: Decimal
                if let amountRaw = transaction.getRichValue(for: RichContentKeys.transfer.amount),
                   let decimal = Decimal(string: amountRaw) {
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
                
                dialogService.dismissProgress()
                chat.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
    
    // MARK: Short description
    
    func shortDescription(for transaction: RichMessageTransaction) -> NSAttributedString {
        let amount: String
        
        guard let raw = transaction.getRichValue(for: RichContentKeys.transfer.amount)
        else {
            return NSAttributedString(string: "⬅️  \(DogeWalletService.currencySymbol)")
        }
        
        if let decimal = Decimal(string: raw) {
            amount = AdamantBalanceFormat.full.format(decimal)
        } else {
            amount = raw
        }
        
        let string: String
        if transaction.isOutgoing {
            string = "⬅️  \(amount) \(DogeWalletService.currencySymbol)"
        } else {
            string = "➡️  \(amount) \(DogeWalletService.currencySymbol)"
        }
        
        return NSAttributedString(string: string)
    }
}
