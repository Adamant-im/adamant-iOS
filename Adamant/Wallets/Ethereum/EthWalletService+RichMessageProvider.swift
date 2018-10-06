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
        guard let richContent = transaction.richContent, let hash = richContent[RichContentKeys.transfer.hash] else {
            return
        }
        
        guard let dialogService = dialogService else {
            return
        }
        
        dialogService.showProgress(withMessage: nil, userInteractionEnable: false)
        
        getTransaction(by: hash) { [weak self] result in
            dialogService.dismissProgress()
            
            switch result {
            case .success(let transaction):
                guard let vc = self?.router.get(scene: AdamantScene.Wallets.Ethereum.transactionDetails) as? EthTransactionDetailsViewController else {
                    return
                }
                
                vc.transaction = transaction
                DispatchQueue.main.async {
                    chat.navigationController?.pushViewController(vc, animated: true)
                }
                
            case .failure(let error):
                self?.dialogService.showRichError(error: error)
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
        
        cell.amountLabel.text = transfer.amount
        cell.dateLabel.text = message.sentDate.humanizedDateTime(withWeekday: false)
        cell.transactionStatus = (message as? RichMessageTransaction)?.transactionStatus
        
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
        guard let amount = transaction.richContent?[RichContentKeys.transfer.amount] else {
            return ""
        }
        
        if transaction.isOutgoing {
            return String.localizedStringWithFormat(String.adamantLocalized.chatList.sentMessagePrefix, " ⬅️  \(amount) \(EthWalletService.currencySymbol)")
        } else {
            return "➡️  \(amount) \(EthWalletService.currencySymbol)"
        }
    }
}
