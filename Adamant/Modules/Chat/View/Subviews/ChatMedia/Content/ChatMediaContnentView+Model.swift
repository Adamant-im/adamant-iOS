//
//  ChatMediaContnentView+Model.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 19.02.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import Foundation
import CommonKit

extension ChatMediaContentView {
    struct Model: Equatable {
        let id: String
        var fileModel: FileModel
        var isHidden: Bool
        let isFromCurrentSender: Bool
        let isReply: Bool
        let replyMessage: NSAttributedString
        let replyId: String
        let comment: NSAttributedString
        let backgroundColor: ChatMessageBackgroundColor
        
        static let `default` = Self(
            id: "",
            fileModel: .default,
            isHidden: false,
            isFromCurrentSender: false,
            isReply: false,
            replyMessage: NSAttributedString(string: .empty),
            replyId: .empty,
            comment: NSAttributedString(string: .empty),
            backgroundColor: .failed
        )
    }
    
    struct FileModel: Equatable {
        var files: [ChatFile]
        var isMediaFilesOnly: Bool
        let isFromCurrentSender: Bool

        static let `default` = Self(
            files: [],
            isMediaFilesOnly: false,
            isFromCurrentSender: false
        )
    }
}
