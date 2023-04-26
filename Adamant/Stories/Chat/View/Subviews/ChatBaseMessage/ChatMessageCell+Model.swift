//
//  ChatMessageCell+Model.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 30.03.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import UIKit
import MessageKit

extension ChatMessageCell {
    struct Model: ChatReusableViewModelProtocol, MessageModel {
        let id: String
        let text: NSAttributedString
        var isSelected: Bool

        static let `default` = Self(
            id: "",
            text: NSAttributedString(string: ""),
            isSelected: false
        )
        
        func makeReplyContent() -> NSAttributedString {
            return text
        }
        
        func height(for width: CGFloat, indexPath: IndexPath, calculator: TextMessageSizeCalculator) -> CGFloat {
            calculator.sizeForItem(at: indexPath).height
        }
    }
}
