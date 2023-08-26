//
//  ChatMessagesListFactory.swift
//  Adamant
//
//  Created by Andrey Golubenko on 08.02.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation
import MessageKit
import Combine
import CommonKit

actor ChatMessagesListFactory {
    private let chatMessageFactory: ChatMessageFactory
    
    init(chatMessageFactory: ChatMessageFactory) {
        self.chatMessageFactory = chatMessageFactory
    }
    
    func makeMessages(
        transactions: [ChatTransaction],
        sender: ChatSender,
        isNeedToLoadMoreMessages: Bool,
        menuMessageID: String?,
        expirationTimestamp minExpTimestamp: inout TimeInterval?
    ) -> [ChatMessage] {
        assert(!Thread.isMainThread, "Do not process messages on main thread")
        
        let transactionsWithoutReact = transactions.filter { chatTransaction in
            guard let transaction = chatTransaction as? RichMessageTransaction,
                  transaction.additionalType == .reaction
            else { return true }
            
            return false
        }
        
        return transactionsWithoutReact.enumerated().map { index, transaction in
            var expTimestamp: TimeInterval?
            let message = makeMessage(
                transaction,
                sender: sender,
                dateHeaderOn: isNeedToDisplayDateHeader(index: index, transactions: transactions),
                topSpinnerOn: isNeedToLoadMoreMessages && index == .zero,
                menuMessageID: menuMessageID,
                willExpireAfter: &expTimestamp
            )
            
            if let timestamp = expTimestamp, timestamp < minExpTimestamp ?? .greatestFiniteMagnitude {
                minExpTimestamp = timestamp
            }
            
            return message
        }
    }
}

private extension ChatMessagesListFactory {
    func makeMessage(
        _ transaction: ChatTransaction,
        sender: SenderType,
        dateHeaderOn: Bool,
        topSpinnerOn: Bool,
        menuMessageID: String?,
        willExpireAfter: inout TimeInterval?
    ) -> ChatMessage {
        var expireDate: Date?
        let message = chatMessageFactory.makeMessage(
            transaction,
            expireDate: &expireDate,
            currentSender: sender,
            dateHeaderOn: dateHeaderOn,
            topSpinnerOn: topSpinnerOn,
            menuMessageID: menuMessageID
        )
        
        willExpireAfter = expireDate?.timeIntervalSince1970
        return message
    }
}

private func isNeedToDisplayDateHeader(
    index: Int,
    transactions: [ChatTransaction]
) -> Bool {
    guard transactions[index].sentDate != .adamantNullDate else { return false }
    guard index > .zero else { return true }
    
    guard
        let previousDate = transactions[index - 1].sentDate,
        let currentDate = transactions[index].sentDate
    else { return false }
    
    let timeIntervalFromLastMessage = currentDate.timeIntervalSince(previousDate)
    return timeIntervalFromLastMessage >= dateHeaderTimeInterval
}

private let dateHeaderTimeInterval: TimeInterval = 3600
