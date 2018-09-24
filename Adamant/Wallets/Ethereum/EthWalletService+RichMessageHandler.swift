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
        guard case .custom(let dataRaw) = message.kind else {
            fatalError("ETH service tried to render wrong message kind: \(message.kind)")
        }
        
        guard let cell = messagesCollectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as? TransferCollectionViewCell else {
            fatalError("Can't dequeue \(cellIdentifier) cell")
        }
        
        cell.currencyLogoImageView.image = EthWalletService.currencyLogo
        cell.currencySymbolLabel.text = EthWalletService.currencySymbol
        
        if let string = dataRaw as? String,
            let data = string.data(using: String.Encoding.utf8),
            let json = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String: Any],
            let amount = json[RichMessageTransfer.CodingKeys.amount.stringValue] as? String {
            cell.amountLabel.text = amount
        } else {
            cell.amountLabel.text = "NaN"
        }
        
        return cell
    }
}
