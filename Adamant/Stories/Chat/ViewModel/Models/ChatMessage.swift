//
//  ChatMessage.swift
//  Adamant
//
//  Created by Andrey Golubenko on 12.01.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import MessageKit
import UIKit

struct ChatMessage: Equatable {
    let messageId: String
    let sentDate: Date
    let senderModel: ChatSender
    let status: Status
    let content: Content
    
    static let `default` = Self(
        messageId: "",
        sentDate: .init(),
        senderModel: .default,
        status: .failed,
        content: .default
    )
}

extension ChatMessage {
    enum Status: Equatable {
        case delivered(blockchain: Bool)
        case pending
        case failed
    }
    
    enum Content: Equatable {
        case message(String)
        case transaction(Transaction)
        
        static let `default` = Self.message("")
    }
    
    struct Transaction: Equatable {
        let icon: UIImage
        let amount: Float
        let currency: String
        let comment: String?
        let status: TransactionStatus
    }
}

extension ChatMessage: MessageType {
    var sender: SenderType {
        senderModel
    }
    
    var kind: MessageKind {
        switch content {
        case let .message(text):
            return .text(text)
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
