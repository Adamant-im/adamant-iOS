//
//  ChatMessageCell+Model.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 30.03.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import UIKit

extension ChatMessageCell {
    struct Model: Equatable, MessageModel {
        let id: String
        let text: NSAttributedString
        
        static let `default` = Self(
            id: "",
            text: NSAttributedString(string: "")
        )
        
        func makeReplyContent() -> NSAttributedString {
            return text
        }
        
        func height(for width: CGFloat) -> CGFloat {
            let maxSize = CGSize(width: width, height: .infinity)
            let titleString = NSAttributedString(string: text.string, attributes: [.font: messageFont])
            
            let titleHeight = titleString.boundingRect(
                with: maxSize,
                options: .usesLineFragmentOrigin,
                context: nil
            ).height
            
            return verticalInsets * 2
                + verticalStackSpacing * 3
                + titleHeight
        }
    }
}

private let messageFont = UIFont.systemFont(ofSize: 17)
private let replyFont = UIFont.systemFont(ofSize: 16)
private let verticalStackSpacing: CGFloat = 6
private let verticalInsets: CGFloat = 8
