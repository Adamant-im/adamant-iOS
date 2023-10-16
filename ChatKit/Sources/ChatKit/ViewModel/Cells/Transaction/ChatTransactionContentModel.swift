//
//  ChatTransactionContentModel.swift
//
//
//  Created by Andrew G on 18.09.2023.
//

import CommonKit
import UIKit

public struct ChatTransactionContentModel: Equatable {
    public let reply: ChatReplyModel?
    public let title: String
    public let icon: UIImage
    public let amount: String
    public let currency: String
    public let date: String
    public let comment: String?
    public let status: ChatItemStatus
    public let onTap: HashableAction
    
    public static let `default` = Self(
        reply: nil,
        title: .empty,
        icon: .init(),
        amount: .empty,
        currency: .empty,
        date: .empty,
        comment: nil,
        status: .pending,
        onTap: .default
    )
    
    public init(
        reply: ChatReplyModel?,
        title: String,
        icon: UIImage,
        amount: String,
        currency: String,
        date: String,
        comment: String?,
        status: ChatItemStatus,
        onTap: HashableAction
    ) {
        self.reply = reply
        self.title = title
        self.icon = icon
        self.amount = amount
        self.currency = currency
        self.date = date
        self.comment = comment
        self.status = status
        self.onTap = onTap
    }
}
