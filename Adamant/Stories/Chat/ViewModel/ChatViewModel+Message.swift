//
//  ChatViewModel+Message.swift
//  Adamant
//
//  Created by Andrey Golubenko on 23.12.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import MessageKit
import Foundation

extension ChatViewModel {
    struct Message: Equatable {
        let messageId: String
        let sentDate: Date
        let senderModel: Sender
        let status: Status
        let text: String
        
        static let `default` = Self(
            messageId: "",
            sentDate: .init(),
            senderModel: .default,
            status: .delivered,
            text: ""
        )
    }
}

extension ChatViewModel.Message {
    enum Status {
        case delivered
        case pending
        case failed
    }
}

extension ChatViewModel.Message: MessageType {
    var sender: SenderType {
        senderModel
    }
    
    var kind: MessageKind {
        .text(text)
    }
}

// ChatViewModel.Message must be the only implementation of MessageType
extension MessageType {
    var fullModel: ChatViewModel.Message {
        if let message = self as? ChatViewModel.Message {
            return message
        } else {
            assertionFailure("Incorrect type")
            return .default
        }
    }
}
