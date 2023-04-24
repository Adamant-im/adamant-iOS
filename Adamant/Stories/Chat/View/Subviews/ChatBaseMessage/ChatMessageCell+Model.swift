//
//  ChatMessageCell+Model.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 30.03.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import UIKit

extension ChatMessageCell {
    struct Model: ChatReusableViewModelProtocol, MessageModel {
        let id: String
        let text: NSAttributedString
        var animationId: String

        static let `default` = Self(
            id: "",
            text: NSAttributedString(string: ""),
            animationId: ""
        )
        
        func makeReplyContent() -> NSAttributedString {
            return text
        }
    }
}
