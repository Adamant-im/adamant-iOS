//
//  EthWalletService+RichMessageProvider.swift
//  Adamant
//
//  Created by Anokhov Pavel on 08.09.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import MessageKit

extension EthWalletService: RichMessageProvider {
    
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
            if address == transaction.senderId {
                senderName = String.adamantLocalized.transactionDetails.yourAddress
            } else {
                senderName = transaction.chatroom?.partner?.name
            }
            
            if address == transaction.recipientId {
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
            dialogService.dismissProgress()
            guard let vc = self?.router.get(scene: AdamantScene.Wallets.Ethereum.transactionDetails) as? EthTransactionDetailsViewController else {
                return
            }
            
            vc.service = self
            vc.senderName = senderName
            vc.recipientName = recipientName
            vc.comment = comment
            
            switch result {
            case .success(let ethTransaction):
                vc.transaction = ethTransaction
                
            case .failure(let error):
                switch error {
                case .remoteServiceError:
                    let amount: Decimal
                    if let amountRaw = transaction.richContent?[RichContentKeys.transfer.amount], let decimal = Decimal(string: amountRaw) {
                        amount = decimal
                    } else {
                        amount = 0
                    }
                    
                    let failedTransaction = SimpleTransactionDetails(id: hash,
                                                             senderAddress: transaction.senderAddress,
                                                             recipientAddress: transaction.recipientAddress,
                                                             dateValue: nil,
                                                             amountValue: amount,
                                                             feeValue: nil,
                                                             confirmationsValue: nil,
                                                             blockValue: nil,
                                                             isOutgoing: transaction.isOutgoing,
                                                             transactionStatus: TransactionStatus.failed)
                    
                    vc.transaction = failedTransaction
                    
                default:
                    self?.dialogService.showRichError(error: error)
                    return
                }
            }
            
            DispatchQueue.main.async {
                chat.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
    
    // MARK: Cells
    
    func cellSizeCalculator(for messagesCollectionViewFlowLayout: MessagesCollectionViewFlowLayout) -> CellSizeCalculator {
        let calculator = TransferMessageSizeCalculator(layout: messagesCollectionViewFlowLayout)
        calculator.font = UIFont.systemFont(ofSize: 24)
        return calculator
    }
    
    func cell(for message: MessageType, isFromCurrentSender: Bool, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UICollectionViewCell {
        guard case .custom(let raw) = message.kind, let transfer = raw as? RichMessageTransfer else {
            fatalError("ETH service tried to render wrong message kind: \(message.kind)")
        }
        
        let cellIdentifier = isFromCurrentSender ? cellIdentifierSent : cellIdentifierReceived
        guard let cell = messagesCollectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as? TransferCollectionViewCell else {
            fatalError("Can't dequeue \(cellIdentifier) cell")
        }
        
        cell.currencyLogoImageView.image = EthWalletService.currencyLogo
        cell.currencySymbolLabel.text = EthWalletService.currencySymbol
        
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
    
    func shortDescription(for transaction: RichMessageTransaction) -> String {
        let amount: String
        
        guard let raw = transaction.richContent?[RichContentKeys.transfer.amount] else {
            return "⬅️  \(EthWalletService.currencySymbol)"
        }
        
        if let decimal = Decimal(string: raw) {
            amount = AdamantBalanceFormat.full.format(decimal)
        } else {
            amount = raw
        }
        
        if transaction.isOutgoing {
            return "⬅️  \(amount) \(EthWalletService.currencySymbol)"
        } else {
            return "➡️  \(amount) \(EthWalletService.currencySymbol)"
        }
    }
}
