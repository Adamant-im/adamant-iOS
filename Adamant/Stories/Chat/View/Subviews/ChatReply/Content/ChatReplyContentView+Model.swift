//
//  ChatReplyContentView+Model.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 24.03.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import UIKit

extension ChatReplyContentView {
    struct Model: Equatable {
        let id: String
        let message: String
        let messageReply: String
        let backgroundColor: ChatMessageBackgroundColor
        
        static let `default` = Self(
            id: "",
            message: "",
            messageReply: "",
            backgroundColor: .failed
        )
    }
}
