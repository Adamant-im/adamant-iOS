//
//  Message+MessageTransaction.swift
//  Adamant
//
//  Created by Andrey Golubenko on 26.12.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import Foundation

extension ChatViewModel.Message {
    init(chatTransaction: ChatTransaction) {
        if let messageTransaction = chatTransaction as? MessageTransaction {
            self.init(messageTransaction: messageTransaction)
            return
        }
        
        self.init(
            messageId: chatTransaction.chatMessageId ?? "",
            sentDate: chatTransaction.date.map { $0 as Date } ?? .init(),
            sender: ChatViewModel.Sender(transaction: chatTransaction),
            status: .init(messageStatus: chatTransaction.statusEnum),
            text: "someChatTransaction"
        )
    }
}

private extension ChatViewModel.Message {
    init(messageTransaction: MessageTransaction) {
        self.messageId = messageTransaction.chatMessageId ?? ""
        self.sentDate = messageTransaction.date.map { $0 as Date } ?? .init()
        self.status = .init(messageStatus: messageTransaction.statusEnum)
        self.text = messageTransaction.message ?? ""
        self.sender = ChatViewModel.Sender(transaction: messageTransaction)
    }
}

private extension ChatViewModel.Message.Status {
    init(messageStatus: MessageStatus) {
        switch messageStatus {
        case .pending:
            self = .pending
        case .delivered:
            self = .delivered
        case .failed:
            self = .failed
        }
    }
}

private extension ChatViewModel.Sender {
    init(transaction: ChatTransaction) {
        self.senderId = transaction.senderId ?? ""
        self.displayName = transaction.senderId ?? ""
    }
}
