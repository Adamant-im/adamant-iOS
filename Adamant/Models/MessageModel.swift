//
//  MessageModel.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 28.03.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation

protocol MessageModel {
    var id: String { get }
    var isFromCurrentSender: Bool { get }
    
    func makeReplyContent() -> NSAttributedString
}

struct BaseMessageModel: Equatable, MessageModel {
    let id: String
    let isFromCurrentSender: Bool
    let text: NSAttributedString
    
    static let `default` = Self(
        id: "",
        isFromCurrentSender: true,
        text: NSAttributedString(string: "")
    )
    
    func makeReplyContent() -> NSAttributedString {
        return text
    }
}
