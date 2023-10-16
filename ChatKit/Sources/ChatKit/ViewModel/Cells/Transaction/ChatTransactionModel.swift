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
    public let reactions: ChatReactionsStackModel
    public let content: ChatTransactionContentModel
    public let statusUpdateAction: HashableAction
    
    public static let `default` = Self(
        id: .empty,
        transactionStatus: .warning,
        reactions: .default,
        content: .default,
        statusUpdateAction: .default
    )
    
    public init(
        id: String,
        transactionStatus: Status,
        reactions: ChatReactionsStackModel,
        content: ChatTransactionContentModel,
        statusUpdateAction: HashableAction
    ) {
        self.id = id
        self.transactionStatus = transactionStatus
        self.reactions = reactions
        self.content = content
        self.statusUpdateAction = statusUpdateAction
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
