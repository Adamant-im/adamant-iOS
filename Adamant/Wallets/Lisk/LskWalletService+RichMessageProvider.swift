//
//  LskWalletService+RichMessageProvider.swift
//  Adamant
//
//  Created by Anton Boyarkin on 06/12/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import MessageKit

extension LskWalletService: RichMessageProvider {
    
    var dynamicRichMessageType: String {
        return type(of: self).richMessageType
    }
    
    // MARK: Events
    
    func richMessageTapped(for transaction: RichMessageTransaction, at indexPath: IndexPath, in chat: ChatViewController) {
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
        
        getTransaction(by: hash) { [weak self] result in
            guard let vc = self?.router.get(scene: AdamantScene.Wallets.Lisk.transactionDetails) as? LskTransactionDetailsViewController else {
                dialogService.dismissProgress()
                return
            }
            
            vc.service = self
            vc.senderName = senderName
            vc.recipientName = recipientName
            vc.comment = comment
            
            switch result {
            case .success(let transaction):
                vc.transaction = transaction
                DispatchQueue.main.async {
                    dialogService.dismissProgress()
                    chat.navigationController?.pushViewController(vc, animated: true)
                }
                
            case .failure(let error):
                switch error {
                case .internalError(let message, _) where message.contains("does not exist"):
                    var recipientAddress = ""
                    var senderAddress = ""
                    let group = DispatchGroup()
                    group.enter()
                    self?.getWalletAddress(byAdamantAddress: transaction.senderAddress) { result in
                        guard case let .success(senderLskAddress) = result else {
                            group.leave()
                            return
                        }
                        senderAddress = senderLskAddress
                        group.leave()
                    }
                    
                    group.enter()
                    self?.getWalletAddress(byAdamantAddress: transaction.recipientAddress) { result in
                        guard case let .success(recipientLskAddress) = result else {
                            group.leave()
                            return
                        }
                        recipientAddress = recipientLskAddress
                        group.leave()
                    }
                    
                    group.notify(queue: .main) {
                        dialogService.dismissProgress()
                        self?.openEmptyTransactionDetail(hash: hash, vc: vc, senderAddress: senderAddress, recipientAddress: recipientAddress, transaction: transaction, in: chat)
                    }

                default:
                    self?.dialogService.showRichError(error: error)
                    return
                }
                break
            }
        }
    }
    
    func openEmptyTransactionDetail(hash: String, vc: LskTransactionDetailsViewController, senderAddress: String, recipientAddress: String, transaction: RichMessageTransaction, in chat: ChatViewController) {
        let amount: Decimal
        if let amountRaw = transaction.richContent?[RichContentKeys.transfer.amount], let decimal = Decimal(string: amountRaw) {
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
                                                         isOutgoing: transaction.isOutgoing,
                                                         transactionStatus: TransactionStatus.pending)

        vc.transaction = failedTransaction
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
            fatalError("LSK service tried to render wrong message kind: \(message.kind)")
        }
        
        let cellIdentifier = isFromCurrentSender ? cellIdentifierSent : cellIdentifierReceived
        guard let cell = messagesCollectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as? TransferCollectionViewCell else {
            fatalError("Can't dequeue \(cellIdentifier) cell")
        }
        
        cell.currencyLogoImageView.image = LskWalletService.currencyLogo
        cell.currencySymbolLabel.text = LskWalletService.currencySymbol
        
        cell.amountLabel.text = AdamantBalanceFormat.full.format(transfer.amount)
        cell.dateLabel.text = message.sentDate.humanizedDateTime(withWeekday: false)
        cell.transactionStatus = (message as? RichMessageTransaction)?.transactionStatus
        
        cell.commentsLabel.text = transfer.comments
        
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
