//
//  ChatDataSourceManager.swift
//  Adamant
//
//  Created by Andrey Golubenko on 23.12.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import MessageKit
import UIKit
import Combine

final class ChatDataSourceManager: MessagesDataSource {
    private let viewModel: ChatViewModel
    
    var currentSender: SenderType {
        viewModel.sender.value
    }
    
    init(viewModel: ChatViewModel) {
        self.viewModel = viewModel
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        viewModel.messages.value.count
    }
    
    func messageForItem(
        at indexPath: IndexPath,
        in messagesCollectionView: MessagesCollectionView
    ) -> MessageType {
        viewModel.messages.value[indexPath.section]
    }
    
    func messageTopLabelAttributedText(
        for message: MessageType,
        at _: IndexPath
    ) -> NSAttributedString? {
        guard message.fullModel.status == .failed else { return nil }
        
        return .init(
            string: .adamantLocalized.chat.failToSend,
            attributes: [
                .font: UIFont.boldSystemFont(ofSize: 10),
                .foregroundColor: UIColor.adamant.primary
            ]
        )
    }
    
    func messageBottomLabelAttributedText(
        for message: MessageType,
        at _: IndexPath
    ) -> NSAttributedString? {
        message.fullModel.bottomString
    }
    
    func cellTopLabelAttributedText(
        for message: MessageType,
        at indexPath: IndexPath
    ) -> NSAttributedString? {
        guard viewModel.isNeedToDisplayDateHeader(sentDate: message.sentDate, index: indexPath.section)
        else { return nil }
        
        return .init(
            string: message.sentDate.humanizedDay(),
            attributes: [
                .font: UIFont.boldSystemFont(ofSize: 10),
                .foregroundColor: UIColor.adamant.secondary
            ]
        )
    }
    
    func customCell(
        for message: MessageType,
        at indexPath: IndexPath,
        in messagesCollectionView: MessagesCollectionView
    ) -> UICollectionViewCell {
        let cell = messagesCollectionView.dequeueReusableCell(
            ChatViewController.TransactionCell.self,
            for: indexPath
        )
        
        viewModel.updateTransactionStatusIfNeeded(id: message.messageId)
        cell.wrappedView.model = message.fullModel.makeTransactionViewModel(
            currentSender: currentSender,
            onTap: { [didTapTransfer = viewModel.didTapTransfer] in
                didTapTransfer.send(message.messageId)
            }
        )
        return cell
    }
}

extension ChatMessage {
    func makeTransactionViewModel(
        currentSender: SenderType,
        onTap: @escaping () -> Void
    ) -> ChatTransactionContainerView.Model {
        guard case let .transaction(model) = content else {
            assertionFailure("Incorrect content type")
            return .default
        }
        
        return .init(
            isFromCurrentSender: sender.senderId == currentSender.senderId,
            status: model.status,
            content: .init(
                title: sender.senderId == currentSender.senderId
                    ? .adamantLocalized.chat.transactionSent
                    : .adamantLocalized.chat.transactionReceived,
                icon: model.icon,
                amount: AdamantBalanceFormat.full.format(model.amount),
                currency: model.currency,
                date: sentDate.humanizedDateTime(withWeekday: false),
                comment: model.comment,
                backgroundColor: getBackgroundColor(currentSender: currentSender),
                action: .init(action: onTap)
            )
        )
    }
}
