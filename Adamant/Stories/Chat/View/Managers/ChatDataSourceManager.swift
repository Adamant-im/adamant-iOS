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

@MainActor
final class ChatDataSourceManager: MessagesDataSource {
    private let viewModel: ChatViewModel
    
    var currentSender: SenderType {
        viewModel.sender
    }
    
    init(viewModel: ChatViewModel) {
        self.viewModel = viewModel
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        viewModel.messages.count
    }
    
    func messageForItem(
        at indexPath: IndexPath,
        in messagesCollectionView: MessagesCollectionView
    ) -> MessageType {
        viewModel.messages[indexPath.section]
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
        message.fullModel.bottomString?.string
    }
    
    func cellTopLabelAttributedText(
        for message: MessageType,
        at indexPath: IndexPath
    ) -> NSAttributedString? {
        message.fullModel.dateHeader?.string
    }
    
    func textCell(
        for message: MessageType,
        at indexPath: IndexPath,
        in messagesCollectionView: MessagesCollectionView
    ) -> UICollectionViewCell? {
        
        if case let .message(model) = message.fullModel.content {
            let cell = messagesCollectionView.dequeueReusableCell(
                ChatMessageCell.self,
                for: indexPath
            )
            
            let publisher: any Observable<ChatMessageCell.Model> = viewModel.$messages.compactMap {
                let message = $0[safe: indexPath.section]
                guard case let .message(model) = message?.fullModel.content
                else { return nil }
                
                let newModel = ChatMessageCell.Model(
                    id: model.id,
                    text: model.string,
                    animationId: message?.animationId ?? ""
                )
                return newModel
            }
            
            let model = ChatMessageCell.Model(id: model.id, text: model.string, animationId: "")
            
            cell.model = model
            cell.configure(with: message, at: indexPath, and: messagesCollectionView)
            cell.actionHandler = { [weak self] in self?.handleAction($0) }
            cell.setSubscription(publisher: publisher)

            return cell
        }
        
        if case let .reply(model) = message.fullModel.content {
            let cell = messagesCollectionView.dequeueReusableCell(
                ChatMessageReplyCell.self,
                for: indexPath
            )
            
            let publisher: any Observable<ChatMessageReplyCell.Model> = viewModel.$messages.compactMap {
                let message = $0[safe: indexPath.section]
                guard case var .reply(model) = message?.fullModel.content
                else { return nil }
                
                model.animationId = message?.animationId ?? ""
                return model
            }
            
            cell.model = model
            cell.configure(with: message, at: indexPath, and: messagesCollectionView)
            cell.actionHandler = { [weak self] in self?.handleAction($0) }
            cell.setSubscription(publisher: publisher)
            
            return cell
        }
        
        return UICollectionViewCell()
    }
    
    func customCell(
        for message: MessageType,
        at indexPath: IndexPath,
        in messagesCollectionView: MessagesCollectionView
    ) -> UICollectionViewCell {
        guard case let .transaction(model) = message.fullModel.content
        else { return UICollectionViewCell() }
        
        let cell = messagesCollectionView.dequeueReusableCell(
            ChatViewController.TransactionCell.self,
            for: indexPath
        )
        
        let publisher: any Observable<ChatTransactionContainerView.Model> = viewModel.$messages.compactMap {
            let message = $0[safe: indexPath.section]
            guard case let .transaction(model) = message?.fullModel.content
            else { return nil }
            
            let newModel = ChatTransactionContainerView.Model.init(
                id: model.value.id,
                isFromCurrentSender: model.value.isFromCurrentSender,
                content: .init(
                    id: model.value.content.id,
                    title: model.value.content.title,
                    icon: model.value.content.icon,
                    amount: model.value.content.amount,
                    currency: model.value.content.currency,
                    date: model.value.content.date,
                    comment: model.value.content.comment,
                    backgroundColor: model.value.content.backgroundColor,
                    animationId: message?.animationId ?? "",
                    isReply: model.value.content.isReply,
                    replyMessage: model.value.content.replyMessage,
                    replyId: model.value.content.replyId),
                status: model.value.status)
            return newModel
        }
        
        cell.wrappedView.model = model.value
        cell.wrappedView.configureColor()
        
        cell.wrappedView.actionHandler = { [weak self] in self?.handleAction($0) }
        cell.wrappedView.setSubscription(publisher: publisher)
        return cell
    }
}

private extension ChatDataSourceManager {
    func handleAction(_ action: ChatAction) {
        switch action {
        case let .openTransactionDetails(id):
            viewModel.didTapTransfer.send(id)
        case let .forceUpdateTransactionStatus(id):
            viewModel.forceUpdateTransactionStatus(id: id)
        case let .reply(message):
            viewModel.replyMessage = message
        case let .scrollTo(message):
            viewModel.scroll(to: message)
        case let .swipeState(state):
            viewModel.swipeState = state
        }
    }
}
