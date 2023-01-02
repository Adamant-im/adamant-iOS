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
            senderModel: .init(transaction: chatTransaction),
            status: .init(messageStatus: chatTransaction.statusEnum),
            text: "someChatTransaction"
        )
    }
}

private extension ChatViewModel.Message {
    init(messageTransaction: MessageTransaction) {
        self.init(
            messageId: messageTransaction.chatMessageId ?? "",
            sentDate: messageTransaction.date.map { $0 as Date } ?? .init(),
            senderModel: .init(transaction: messageTransaction),
            status: .init(messageStatus: messageTransaction.statusEnum),
            text: messageTransaction.message ?? ""
        )
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
        self.init(
            senderId: transaction.senderId ?? "",
            displayName: transaction.senderId ?? ""
        )
    }
}
