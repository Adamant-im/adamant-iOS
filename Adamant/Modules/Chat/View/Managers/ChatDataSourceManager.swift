//
//  ChatDataSourceManager.swift
//  Adamant
//
//  Created by Andrey Golubenko on 23.12.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

@preconcurrency import MessageKit
import UIKit
import Combine
import CommonKit

@MainActor
final class ChatDataSourceManager: MessagesDataSource {
    private let viewModel: ChatViewModel
    
    nonisolated var currentSender: SenderType {
        MainActor.assumeIsolatedSafe {
            viewModel.sender
        }
    }
    
    init(viewModel: ChatViewModel) {
        self.viewModel = viewModel
    }
    
    nonisolated func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        MainActor.assumeIsolatedSafe { viewModel.messages.count }
    }
    
    nonisolated func messageForItem(
        at indexPath: IndexPath,
        in messagesCollectionView: MessagesCollectionView
    ) -> MessageType {
        MainActor.assumeIsolatedSafe { viewModel.messages[indexPath.section] }
    }
    
    nonisolated func messageTopLabelAttributedText(
        for message: MessageType,
        at _: IndexPath
    ) -> NSAttributedString? {
        MainActor.assumeIsolatedSafe {
            guard message.fullModel.status == .failed else { return nil }
            
            return .init(
                string: .adamant.chat.failToSend,
                attributes: [
                    .font: UIFont.boldSystemFont(ofSize: 10),
                    .foregroundColor: UIColor.adamant.primary
                ]
            )
        }
    }
    
    nonisolated func messageBottomLabelAttributedText(
        for message: MessageType,
        at _: IndexPath
    ) -> NSAttributedString? {
        message.fullModel.bottomString?.string
    }
    
    nonisolated func cellTopLabelAttributedText(
        for message: MessageType,
        at indexPath: IndexPath
    ) -> NSAttributedString? {
        message.fullModel.dateHeader?.string
    }
    
    nonisolated func textCell(
        for message: MessageType,
        at indexPath: IndexPath,
        in messagesCollectionView: MessagesCollectionView
    ) -> UICollectionViewCell? {
        MainActor.assumeIsolatedSafe {
            if case let .message(model) = message.fullModel.content {
                let cell = messagesCollectionView.dequeueReusableCell(
                    ChatMessageCell.self,
                    for: indexPath
                )
                
                let publisher: any Observable<ChatMessageCell.Model> = viewModel.$messages.compactMap {
                    let message = $0[safe: indexPath.section]
                    guard case let .message(model) = message?.fullModel.content
                    else { return nil }
                    
                    return model.value
                }
                
                cell.actionHandler = { [weak self] in self?.handleAction($0) }
                cell.chatMessagesListViewModel = viewModel.chatMessagesListViewModel
                cell.model = model.value
                cell.configure(with: message, at: indexPath, and: messagesCollectionView)
                cell.setSubscription(publisher: publisher, collection: messagesCollectionView)
                return cell
            }
            
            if case let .reply(model) = message.fullModel.content {
                let cell = messagesCollectionView.dequeueReusableCell(
                    ChatMessageReplyCell.self,
                    for: indexPath
                )
                
                let publisher: any Observable<ChatMessageReplyCell.Model> = viewModel.$messages.compactMap {
                    let message = $0[safe: indexPath.section]
                    guard case let .reply(model) = message?.fullModel.content
                    else { return nil }
                    
                    return model.value
                }
                
                cell.actionHandler = { [weak self] in self?.handleAction($0) }
                cell.chatMessagesListViewModel = viewModel.chatMessagesListViewModel
                cell.model = model.value
                cell.configure(with: message, at: indexPath, and: messagesCollectionView)
                cell.setSubscription(publisher: publisher, collection: messagesCollectionView)
                return cell
            }
            
            return UICollectionViewCell()
        }
    }
    
    nonisolated func customCell(
        for message: MessageType,
        at indexPath: IndexPath,
        in messagesCollectionView: MessagesCollectionView
    ) -> UICollectionViewCell {
        MainActor.assumeIsolatedSafe {
            if case let .transaction(model) = message.fullModel.content {
                let cell = messagesCollectionView.dequeueReusableCell(
                    ChatTransactionCell.self,
                    for: indexPath
                )
                
                let publisher: any Observable<ChatTransactionContainerView.Model> = viewModel.$messages.compactMap {
                    let message = $0[safe: indexPath.section]
                    guard case let .transaction(model) = message?.fullModel.content
                    else { return nil }
                    
                    return model.value
                }
                
                cell.transactionView.wrappedView.actionHandler = { [weak self] in self?.handleAction($0) }
                cell.transactionView.wrappedView.chatMessagesListViewModel = viewModel.chatMessagesListViewModel
                cell.transactionView.wrappedView.model = model.value
                cell.transactionView.wrappedView.setSubscription(publisher: publisher, collection: messagesCollectionView)
                cell.configure(with: message, at: indexPath, and: messagesCollectionView)
                return cell
            }
            
            if case let .file(model) = message.fullModel.content {
                let cell = messagesCollectionView.dequeueReusableCell(
                    ChatMediaCell.self,
                    for: indexPath
                )
                
                let publisher: any Observable<ChatMediaContainerView.Model> = viewModel.$messages.compactMap {
                    let message = $0[safe: indexPath.section]
                    guard case let .file(model) = message?.fullModel.content
                    else { return nil }
                    
                    return model.value
                }
                
                cell.containerMediaView.wrappedView.actionHandler = { [weak self] in self?.handleAction($0) }
                cell.containerMediaView.wrappedView.chatMessagesListViewModel = viewModel.chatMessagesListViewModel
                cell.containerMediaView.wrappedView.model = model.value
                cell.containerMediaView.wrappedView.setSubscription(publisher: publisher, collection: messagesCollectionView)
                cell.configure(with: message, at: indexPath, and: messagesCollectionView)
                return cell
            }
            
            return UICollectionViewCell()
        }
    }
}

private extension ChatDataSourceManager {
    func handleAction(_ action: ChatAction) {
        switch action {
        case let .openTransactionDetails(id):
            viewModel.didTapTransfer.send(id)
        case let .forceUpdateTransactionStatus(id):
            viewModel.forceUpdateTransactionStatus(id: id)
        case let .reply(id):
            viewModel.replyMessageIfNeeded(id: id)
        case let .scrollTo(message):
            viewModel.scroll(to: message)
        case let .copy(text):
            viewModel.copyMessageAction(text)
        case let .remove(id):
            viewModel.removeMessageAction(id)
        case let .report(id):
            viewModel.reportMessageAction(id)
        case let .react(id, emoji):
            viewModel.reactAction(id, emoji: emoji)
        case let .presentMenu(arg):
            viewModel.presentMenu(arg: arg)
        case .copyInPart(text: let text):
            viewModel.copyTextInPartAction(text)
        case let .openFile(messageId, file):
            viewModel.openFile(messageId: messageId, file: file)
        case let .autoDownloadContentIfNeeded(messageId, files):
            viewModel.autoDownloadContentIfNeeded(
                messageId: messageId,
                files: files
            )
        case let .forceDownloadAllFiles(messageId, files):
            viewModel.forceDownloadAllFiles(messageId: messageId, files: files)
        }
    }
}
