//
//  ChatDisplayManager.swift
//  Adamant
//
//  Created by Andrey Golubenko on 23.12.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import MessageKit
import UIKit
import Combine

final class ChatDisplayManager: MessagesDisplayDelegate {
    private let viewModel: ChatViewModel
    
    init(viewModel: ChatViewModel) {
        self.viewModel = viewModel
    }
    
    func messageStyle(
        for message: MessageType,
        at _: IndexPath,
        in _: MessagesCollectionView
    ) -> MessageStyle {
        .bubbleTail(
            message.sender.senderId == viewModel.sender.senderId
                ? .bottomRight
                : .bottomLeft,
            .curved
        )
    }
    
    func backgroundColor(
        for message: MessageType,
        at _: IndexPath,
        in _: MessagesCollectionView
    ) -> UIColor {
        message.fullModel.getBackgroundColor(currentSender: viewModel.sender)
    }
    
    func textColor(
        for _: MessageType,
        at _: IndexPath,
        in _: MessagesCollectionView
    ) -> UIColor { .adamant.primary }
    
    func messageHeaderView(
        for indexPath: IndexPath,
        in messagesCollectionView: MessagesCollectionView
    ) -> MessageReusableView {
        let header = messagesCollectionView.dequeueReusableHeaderView(
            ChatViewController.SpinnerCell.self,
            for: indexPath
        )
        
        if indexPath.section == .zero, viewModel.loadingStatus == .onTop {
            header.wrappedView.startAnimating()
        } else {
            header.wrappedView.stopAnimating()
        }
        
        return header
    }
    
    func enabledDetectors(
        for _: MessageType,
        at _: IndexPath,
        in _: MessagesCollectionView
    ) -> [DetectorType] {
        return [.url]
    }
    
    func detectorAttributes(
        for detector: DetectorType,
        and _: MessageType,
        at _: IndexPath
    ) -> [NSAttributedString.Key: Any] {
        return detector == .url
            ? [.foregroundColor: UIColor.adamant.active]
            : [:]
    }
}

extension ChatMessage {
    func getBackgroundColor(currentSender: SenderType) -> UIColor {
        guard sender.senderId == currentSender.senderId else {
            return .adamant.chatRecipientBackground
        }
        
        switch status {
        case .delivered:
            return .adamant.chatSenderBackground
        case .pending:
            return .adamant.pendingChatBackground
        case .failed:
            return .adamant.failChatBackground
        }
    }
}
