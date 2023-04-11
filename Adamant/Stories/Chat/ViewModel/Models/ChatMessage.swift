//
//  ChatMessage.swift
//  Adamant
//
//  Created by Andrey Golubenko on 12.01.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import MessageKit
import UIKit

struct ChatMessage: Identifiable, Equatable {
    let id: String
    let sentDate: Date
    let senderModel: ChatSender
    let status: Status
    let content: Content
    let backgroundColor: ChatMessageBackgroundColor
    let bottomString: ComparableAttributedString?
    let dateHeader: ComparableAttributedString?
    let topSpinnerOn: Bool
    
    static let `default` = Self(
        id: "",
        sentDate: .init(),
        senderModel: .default,
        status: .failed,
        content: .default,
        backgroundColor: .failed,
        bottomString: nil,
        dateHeader: nil,
        topSpinnerOn: false
    )
}

extension ChatMessage {
    struct EqualWrapper<Value>: Equatable {
        let value: Value
        
        static func == (lhs: Self, rhs: Self) -> Bool { true }
    }
    
    enum Status: Equatable {
        case delivered(blockchain: Bool)
        case pending
        case failed
    }
    
    enum Content: Equatable {
        case message(ComparableAttributedString)
        case transaction(EqualWrapper<ChatTransactionContainerView.Model>)
        
        static let `default` = Self.message(.init(string: .init()))
    }
}

extension ChatMessage: MessageType {
    var messageId: String { id }
    var sender: SenderType { senderModel }
    
    var kind: MessageKind {
        switch content {
        case let .message(text):
            return .attributedText(text.string)
        case let .transaction(model):
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
