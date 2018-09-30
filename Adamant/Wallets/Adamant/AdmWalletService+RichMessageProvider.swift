//
//  AdmWalletService+RichMessageProvider.swift
//  Adamant
//
//  Created by Anokhov Pavel on 27.09.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import MessageKit

extension AdmWalletService: RichMessageProvider {
    func richMessageTapped(_ message: MessageType, at indexPath: IndexPath, in chat: ChatViewController) {
        guard let transaction = message as? TransferTransaction else {
            return
        }
        
        guard let vc = router.get(scene: AdamantScene.Wallets.Adamant.transactionDetails) as? BaseTransactionDetailsViewController else {
            fatalError("Can't get TransactionDetails scene")
        }
        
        vc.transaction = transaction
        
        if let nav = chat.navigationController {
            nav.pushViewController(vc, animated: true)
        } else {
            chat.present(vc, animated: true, completion: nil)
        }
    }
    
    func cellSizeCalculator(for messagesCollectionViewFlowLayout: MessagesCollectionViewFlowLayout) -> CellSizeCalculator {
        let calculator = TransferMessageSizeCalculator(layout: messagesCollectionViewFlowLayout)
        calculator.font = UIFont.systemFont(ofSize: 24)
        return calculator
    }
    
    func cell(for message: MessageType, isFromCurrentSender: Bool, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UICollectionViewCell {
        guard case .custom(let raw) = message.kind, let richMessage = raw as? RichMessageTransfer else {
            fatalError("ADM service tried to render wrong message kind: \(message.kind)")
        }
        
        guard let cell = messagesCollectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as? TransferCollectionViewCell else {
            fatalError("Can't dequeue \(cellIdentifier) cell")
        }
        
        cell.currencyLogoImageView.image = AdmWalletService.currencyLogo
        cell.currencySymbolLabel.text = AdmWalletService.currencySymbol
        
        cell.amountLabel.text = richMessage.amount
        cell.dateLabel.text = message.sentDate.humanizedDateTime(withWeekday: false)
        
        cell.isAlignedRight = isFromCurrentSender
        
        return cell
    }
}
