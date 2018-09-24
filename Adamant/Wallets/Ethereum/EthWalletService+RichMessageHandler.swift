//
//  EthWalletService+RichMessageHandler.swift
//  Adamant
//
//  Created by Anokhov Pavel on 08.09.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import MessageKit

extension EthWalletService: RichMessageProvider {
    func richMessageTapped(message: MessageTransaction, in chat: ChatViewController) {
        print("tap!")
    }
    
    func cellSizeCalculator(for messagesCollectionViewFlowLayout: MessagesCollectionViewFlowLayout) -> CellSizeCalculator {
        let calculator = TransferMessageSizeCalculator(layout: messagesCollectionViewFlowLayout)
        calculator.font = UIFont.systemFont(ofSize: 24)
        return calculator
    }
    
    func cell(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UICollectionViewCell {
        guard case .custom(let raw) = message.kind, let richContent = raw as? [String:String] else {
            fatalError("ETH service tried to render wrong message kind: \(message.kind)")
        }
        
        guard let cell = messagesCollectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as? TransferCollectionViewCell else {
            fatalError("Can't dequeue \(cellIdentifier) cell")
        }
        
        cell.currencyLogoImageView.image = EthWalletService.currencyLogo
        cell.currencySymbolLabel.text = EthWalletService.currencySymbol
        
        cell.amountLabel.text = richContent[RichContentKeys.transfer.amount] ?? "NaN"
        
        return cell
    }
}
