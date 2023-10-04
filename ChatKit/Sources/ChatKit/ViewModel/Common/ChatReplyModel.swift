//
//  ChatReplyModel.swift
//
//
//  Created by Andrew G on 18.09.2023.
//

import CommonKit
import Foundation

public struct ChatReplyModel: Equatable {
    public let replyText: NSAttributedString
    public let onTap: HashableAction
    
    public static let `default` = Self(replyText: .init(), onTap: .default)
    
    public init(replyText: NSAttributedString, onTap: HashableAction) {
        self.replyText = replyText
        self.onTap = onTap
    }
}
