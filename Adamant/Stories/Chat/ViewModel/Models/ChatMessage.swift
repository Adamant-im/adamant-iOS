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
    let bottomString: ComparableAttributedString?
    
    static let `default` = Self(
        id: "",
        sentDate: .init(),
        senderModel: .default,
        status: .failed,
        content: .default,
        bottomString: nil
    )
}

extension ChatMessage {
    enum Status: Equatable {
        case delivered(blockchain: Bool)
        case pending
        case failed
    }
    
    enum Content: Equatable {
        case message(ComparableAttributedString)
        case transaction(Transaction)
        
        static let `default` = Self.message(.init(string: .init()))
    }
    
    struct Transaction: Equatable {
        let icon: UIImage
        let amount: Decimal
        let currency: String
        let comment: String?
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
