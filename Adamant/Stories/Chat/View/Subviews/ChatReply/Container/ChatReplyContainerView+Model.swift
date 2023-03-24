//
//  ChatReplyContainerView+Model.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 24.03.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation

extension ChatReplyContainerView {
    struct Model: Equatable {
        let id: String
        let isFromCurrentSender: Bool
        let content: ChatReplyContentView.Model
        
        static let `default` = Self(
            id: "",
            isFromCurrentSender: true,
            content: .default
        )
    }
}
