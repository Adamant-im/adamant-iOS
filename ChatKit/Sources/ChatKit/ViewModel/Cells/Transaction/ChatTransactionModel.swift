//
//  ChatTransactionModel.swift
//
//
//  Created by Andrew G on 18.09.2023.
//

import CommonKit

public struct ChatTransactionModel: Equatable {
    public let id: String
    public let transactionStatus: Status
    public let firstReaction: ChatReactionModel?
    public let secondReaction: ChatReactionModel?
    public let content: ChatTransactionContentModel
    
    public static let `default` = Self(
        id: .empty,
        transactionStatus: .warning,
        firstReaction: nil,
        secondReaction: nil,
        content: .default
    )
    
    public init(
        id: String,
        transactionStatus: Status,
        firstReaction: ChatReactionModel?,
        secondReaction: ChatReactionModel?,
        content: ChatTransactionContentModel
    ) {
        self.id = id
        self.transactionStatus = transactionStatus
        self.firstReaction = firstReaction
        self.secondReaction = secondReaction
        self.content = content
    }
}

public extension ChatTransactionModel {
    enum Status {
        case success
        case pending
        case warning
        case failed
        case none
    }
}
