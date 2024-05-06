//
//  FilePresentationHelper.swift
//  
//
//  Created by Stanislav Jelezoglo on 26.04.2024.
//

import Foundation

public class FilePresentationHelper {
    public static func getFilePresentationText(
        mediaFilesCount: Int,
        otherFilesCount: Int,
        comment: String
    ) -> String {
        let mediaCountText = mediaFilesCount > 1
        ? "\(mediaFilesCount)"
        : .empty
        
        let otherFilesCountText = otherFilesCount > 1
        ? "\(otherFilesCount)"
        : .empty
        
        let mediaText = mediaFilesCount > 0 ? "📸\(mediaCountText)" : .empty
        let fileText = otherFilesCount > 0 ? "📄\(otherFilesCountText)" : .empty
        
        let text = [mediaText, fileText, comment].filter {
            !$0.isEmpty
        }.joined(separator: " ")
        
        return text
    }
    
    public static func getFilePresentationText(_ richContent: [String: Any]) -> String {
        let content = richContent[RichContentKeys.reply.replyMessage] as? [String: Any] ?? richContent
        
        let files = content[RichContentKeys.file.files] as? [[String: Any]] ?? []
        
        let mediaFilesCount = files.filter { file in
            let fileTypeRaw = file[RichContentKeys.file.type] as? String ?? .empty
            let fileType = FileType(raw: fileTypeRaw) ?? .other
            return fileType == .image || fileType == .video
        }.count
        
        let otherFilesCount = files.count - mediaFilesCount
        
        let comment = (content[RichContentKeys.file.comment] as? String).flatMap {
            $0.isEmpty ? nil : $0
        } ?? .empty
        
        return Self.getFilePresentationText(
            mediaFilesCount: mediaFilesCount,
            otherFilesCount: otherFilesCount,
            comment: comment
        )
    }
}
