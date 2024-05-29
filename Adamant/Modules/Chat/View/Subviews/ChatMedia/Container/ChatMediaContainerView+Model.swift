//
//  ChatMediaContainerView+Model.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 19.02.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import Foundation
import CommonKit

extension ChatMediaContainerView {
    struct Model: ChatReusableViewModelProtocol, MessageModel {
        let id: String
        let isFromCurrentSender: Bool
        let reactions: Set<Reaction>?
        var content: ChatMediaContentView.Model
        let address: String
        let opponentAddress: String
        let txStatus: MessageStatus
        
        var status: FileMessageStatus {
            if txStatus == .failed {
                return .failed
            }
            
            if content.fileModel.files.first(where: { $0.isBusy }) != nil {
                return .busy
            }
            
            if content.fileModel.files.contains(where: {
                !$0.isCached ||
                ($0.isCached
                 && $0.file.preview != nil
                 && $0.previewImage == nil
                 && ($0.fileType == .image || $0.fileType == .video))
            }) {
                return .needToDownload
            }
            
            return .success
        }
        
        static let `default` = Self(
            id: "",
            isFromCurrentSender: true,
            reactions: nil,
            content: .default,
            address: "",
            opponentAddress: "",
            txStatus: .failed
        )
        
        func makeReplyContent() -> NSAttributedString {
            let mediaFilesCount = content.fileModel.files.filter { file in
                return file.fileType == .image || file.fileType == .video
            }.count
            
            let otherFilesCount = content.fileModel.files.count - mediaFilesCount
            
            let comment = content.comment.string
            
            let text = FilePresentationHelper.getFilePresentationText(
                mediaFilesCount: mediaFilesCount,
                otherFilesCount: otherFilesCount,
                comment: comment
            )
           
            return ChatMessageFactory.markdownParser.parse(text)
        }
    }
}
