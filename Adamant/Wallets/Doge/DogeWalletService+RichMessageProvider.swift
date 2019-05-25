//
//  DogeWalletService+RichMessageProvider.swift
//  Adamant
//
//  Created by Anton Boyarkin on 13/03/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import Foundation
import MessageKit

extension DogeWalletService: RichMessageProvider {
    
    // MARK: Events
    
    func richMessageTapped(for transaction: RichMessageTransaction, at indexPath: IndexPath, in chat: ChatViewController) {
        // MARK: 0. Prepare
        guard let richContent = transaction.richContent,
            let hash = richContent[RichContentKeys.transfer.hash],
            let dialogService = dialogService,
            let address = wallet?.address else {
                return
        }
        
        dialogService.showProgress(withMessage: nil, userInteractionEnable: false)
        
        let comment: String?
        if let raw = transaction.richContent?[RichContentKeys.transfer.comments], raw.count > 0 {
            comment = raw
        } else {
            comment = nil
        }
        
        // MARK: Get transaction
        getTransaction(by: hash) { [weak self] result in
            guard let vc = self?.router.get(scene: AdamantScene.Wallets.Doge.transactionDetails) as? DogeTransactionDetailsViewController, let service = self else {
                return
            }
            
            // MARK: 1. Prepare details view controller
            vc.service = service
            vc.comment = comment
            
            switch result {
            case .success(let dogeRawTransaction):
                let dogeTransaction = dogeRawTransaction.asBtcTransaction(DogeTransaction.self, for: address)
                
                // MARK: 2. Self name
                if dogeTransaction.senderAddress == address {
                    vc.senderName = String.adamantLocalized.transactionDetails.yourAddress
                }
                if dogeTransaction.recipientAddress == address {
                    vc.recipientName = String.adamantLocalized.transactionDetails.yourAddress
                }
                
                vc.transaction = dogeTransaction
                
                let group = DispatchGroup()
                
                // MARK: 3. Get partner name async
                if let partner = transaction.partner, let partnerAddress = partner.address, let partnerName = partner.name {
                    group.enter() // Enter 1
                    service.getDogeAddress(byAdamandAddress: partnerAddress) { result in
                        switch result {
                        case .success(let address):
                            if dogeTransaction.senderAddress == address {
                                vc.senderName = partnerName
                            }
                            if dogeTransaction.recipientAddress == address {
                                vc.recipientName = partnerName
                            }
                            
                        case .failure:
                            break
                        }
                        
                        group.leave() // Leave 1
                    }
                }
                
                // MARK: 4. Get block id async
                if let blockHash = dogeRawTransaction.blockHash {
                    group.enter() // Enter 2
                    service.getBlockId(by: blockHash) { result in
                        switch result {
                        case .success(let id):
                            vc.transaction = dogeRawTransaction.asBtcTransaction(DogeTransaction.self, for: address, blockId: id)
                            
                        case .failure:
                            break
                        }
                        
                        group.leave() // Leave 2
                    }
                }
                
                // MARK: 5. Wait async operations
                group.wait()
                
                // MARK: 6. Display details view controller
                DispatchQueue.main.async {
                    dialogService.dismissProgress()
                    chat.navigationController?.pushViewController(vc, animated: true)
                }
                
            case .failure(let error):
                switch error {
                case .internalError(let message, _) where message == "No transaction":
                    let amount: Decimal
                    if let amountRaw = transaction.richContent?[RichContentKeys.transfer.amount], let decimal = Decimal(string: amountRaw) {
                        amount = decimal
                    } else {
                        amount = 0
                    }
                    
                    let failedTransaction = SimpleTransactionDetails(txId: hash,
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
                    
                    DispatchQueue.main.async {
                        dialogService.dismissProgress()
                        chat.navigationController?.pushViewController(vc, animated: true)
                    }
                    
                default:
                    dialogService.dismissProgress()
                    dialogService.showRichError(error: error)
                }
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
            fatalError("DOGE service tried to render wrong message kind: \(message.kind)")
        }
        
        let cellIdentifier = isFromCurrentSender ? cellIdentifierSent : cellIdentifierReceived
        guard let cell = messagesCollectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as? TransferCollectionViewCell else {
            fatalError("Can't dequeue \(cellIdentifier) cell")
        }
        
        cell.currencyLogoImageView.image = DogeWalletService.currencyLogo
        cell.currencySymbolLabel.text = DogeWalletService.currencySymbol
        
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
