//
//  ChatMessageModel.swift
//
//
//  Created by Andrew G on 18.09.2023.
//

import Foundation

public struct ChatMessageModel: Equatable {
    public let id: String
    public let content: ChatMessageContentModel
    public let topString: NSAttributedString?
    public let bottomString: NSAttributedString
    public let reactions: ChatReactionsStackModel
    
    public static let `default` = Self(
        id: .empty,
        content: .default,
        topString: nil,
        bottomString: .init(),
        reactions: .default
    )
    
    public init(
        id: String,
        content: ChatMessageContentModel,
        topString: NSAttributedString?,
        bottomString: NSAttributedString,
        reactions: ChatReactionsStackModel
    ) {
        self.id = id
        self.content = content
        self.topString = topString
        self.bottomString = bottomString
        self.reactions = reactions
    }
}
