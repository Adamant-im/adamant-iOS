//
//  ChatMessage.swift
//  Adamant
//
//  Created by Andrey Golubenko on 12.01.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import MessageKit
import UIKit
import CommonKit

struct ChatMessage: Identifiable, Equatable, Sendable {
    let id: String
    let sentDate: Date
    let senderModel: ChatSender
    let status: Status
    var content: Content
    let backgroundColor: ChatMessageBackgroundColor
    let bottomString: ComparableAttributedString?
    let dateHeader: ComparableAttributedString?
    let topSpinnerOn: Bool
    let dateHeaderIsHidden: Bool
    var isUnread: Bool
    var unreadMode: UnreadMode?
    
    static var `default`: Self {
        Self(
            id: "",
            sentDate: .init(),
            senderModel: .default,
            status: .failed,
            content: .default,
            backgroundColor: .failed,
            bottomString: nil,
            dateHeader: nil,
            topSpinnerOn: false,
            dateHeaderIsHidden: true,
            isUnread: true,
            unreadMode: .top
        )
    }
}

extension ChatMessage {
    struct EqualWrapper<Value: Sendable>: Equatable {
        let value: Value
        
        static func == (lhs: Self, rhs: Self) -> Bool { true }
    }
    
    enum Status: Equatable {
        case delivered(blockchain: Bool)
        case pending
        case failed
    }
    
    enum Content: Equatable, Sendable {
        case message(EqualWrapper<ChatMessageCell.Model>)
        case transaction(EqualWrapper<ChatTransactionContainerView.Model>)
		case reply(EqualWrapper<ChatMessageReplyCell.Model>)
        case file(EqualWrapper<ChatMediaContainerView.Model>)
        
        static var `default`: Self {
            Self.message(.init(value: .default))
        }
    }
}

extension ChatMessage: MessageType {
    var messageId: String { id }
    var sender: SenderType { senderModel }
    
    var kind: MessageKind {
        switch content {
        case let .message(model):
            return .attributedText(model.value.text)
        case let .transaction(model):
            return .custom(model)
        case let .reply(model):
            let message = model.value.message.string.count > model.value.messageReply.string.count
            ? model.value.message
            : model.value.messageReply
            return .attributedText(message)
        case let .file(model):
            return .custom(model)
        }
    }
}

// ChatMessage must be the only implementation of MessageType
extension MessageType {
    var fullModel: ChatMessage {
        if let message = self as? ChatMessage {
            return message
        } else {
            assertionFailure("Incorrect type")
            return .default
        }
    }
}
enum UnreadMode {
    case top
    case bottom
}
