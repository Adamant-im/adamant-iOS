//
//  ChatReactionModel.swift
//
//
//  Created by Andrew G on 18.09.2023.
//

import UIKit
import CommonKit

public struct ChatReactionModel: Equatable {
    public let emoji: String
    public let image: UIImage?
    public let onTap: HashableAction
    
    public static let `default` = Self(emoji: .empty, image: nil, onTap: .default)
    
    public init(emoji: String, image: UIImage?, onTap: HashableAction) {
        self.emoji = emoji
        self.image = image
        self.onTap = onTap
    }
}
