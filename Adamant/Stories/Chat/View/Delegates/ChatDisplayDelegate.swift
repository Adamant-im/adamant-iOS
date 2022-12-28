//
//  ChatDisplayDelegate.swift
//  Adamant
//
//  Created by Andrey Golubenko on 23.12.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import MessageKit
import UIKit
import Combine

final class ChatDisplayDelegate: MessagesDisplayDelegate {
    private let currentSender: ObservableVariable<ChatViewModel.Sender>
    
    init(currentSender: ObservableVariable<ChatViewModel.Sender>) {
        self.currentSender = currentSender
    }
    
    func messageStyle(
        for message: MessageType,
        at _: IndexPath,
        in _: MessagesCollectionView
    ) -> MessageStyle {
        .bubbleTail(
            message.sender.senderId == currentSender.value.senderId
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
        guard message.sender.senderId == currentSender.value.senderId else {
            return .adamant.chatRecipientBackground
        }
        
        switch message.fullModel.status {
        case .delivered:
            return .adamant.chatSenderBackground
        case .pending:
            return .adamant.pendingChatBackground
        case .failed:
            return .adamant.failChatBackground
        }
    }
    
    func textColor(
        for _: MessageType,
        at _: IndexPath,
        in _: MessagesCollectionView
    ) -> UIColor { .adamant.primary }
}
