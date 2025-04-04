//
//  FilePresentationHelper.swift
//  
//
//  Created by Stanislav Jelezoglo on 26.04.2024.
//

import Foundation
import MarkdownKit

public class FilePresentationHelper {
    public static func getFilePresentationText(
        mediaFilesCount: Int,
        otherFilesCount: Int,
        comment: String,
        parsedWith parser: MarkdownParser? = nil, 
        resolveLinkColor: Bool = false
    ) -> NSMutableAttributedString {
        let prefix = getFilePrefix(mediaFilesCount: mediaFilesCount, otherFilesCount: otherFilesCount)
        
        var parsedEmodji = parser?.parse(prefix)        
        var parsedComment = parser?.parse(comment)
        
        if resolveLinkColor {
            parsedEmodji = (parsedEmodji ?? NSAttributedString()).resolveLinkColor()
            parsedComment = (parsedComment ?? NSAttributedString()).resolveLinkColor()
        }
        
        let result = NSMutableAttributedString(attributedString: parsedEmodji ?? NSAttributedString())
        result.append(parsedComment ?? NSMutableAttributedString())
        
        return result
    }
    
    public static func getFilePresentationText(_ richContent: [String: Any]) -> String {
        return getFilePrefix(richContent) + getText(from: richContent)
    }
    
    public static func getFilePresentationText(_ richContent: [String: Any], parsedWith parser: MarkdownParser? = nil, resolveLinkColor: Bool = false) -> NSMutableAttributedString {
        guard parser != nil else {
            return NSMutableAttributedString(string: getFilePresentationText(richContent))
        }
        
        let emodji = getFilePrefix(richContent)
        let comment = getText(from: richContent)
        
        var parsedEmodji = parser?.parse(emodji)        
        var parsedComment = parser?.parse(comment)
        
        if resolveLinkColor {
            parsedEmodji = (parsedEmodji ?? NSAttributedString()).resolveLinkColor()
            parsedComment = (parsedComment ?? NSAttributedString()).resolveLinkColor()
        }
        
        let result = NSMutableAttributedString(attributedString: parsedEmodji ?? NSAttributedString())
        result.append(parsedComment ?? NSMutableAttributedString())
        
        return result
    }
    
    private static func getText(from richContent: [String: Any]) -> String {
        let content = richContent[RichContentKeys.reply.replyMessage] as? [String: Any] ?? richContent
        return (content[RichContentKeys.file.comment] as? String).flatMap {
            $0.isEmpty ? nil : $0
        } ?? .empty
    }
    
    private static func getFilePrefix(_ richContent: [String: Any]) -> String {
        let content = richContent[RichContentKeys.reply.replyMessage] as? [String: Any] ?? richContent
        
        let files = content[RichContentKeys.file.files] as? [[String: Any]] ?? []
        
        let mediaFilesCount = files.filter { file in
            let mimeType = file[RichContentKeys.file.mimeType] as? String ?? .empty
            let fileType = FileType(mimeType: mimeType) ?? .other
            return fileType == .image || fileType == .video
        }.count
        
        let otherFilesCount = files.count - mediaFilesCount
        
        return Self.getFilePrefix(
            mediaFilesCount: mediaFilesCount,
            otherFilesCount: otherFilesCount
        )
    }
    
    private static func getFilePrefix(
        mediaFilesCount: Int,
        otherFilesCount: Int
    ) -> String {
        let mediaCountText = mediaFilesCount > 1
        ? "\(mediaFilesCount)"
        : .empty
        
        let otherFilesCountText = otherFilesCount > 1
        ? "\(otherFilesCount)"
        : .empty
        
        let mediaText = mediaFilesCount > 0 ? "📸\(mediaCountText)" : .empty
        let fileText = otherFilesCount > 0 ? "📄\(otherFilesCountText)" : .empty
        
        let text = [mediaText, fileText].filter {
            !$0.isEmpty
        }.joined()
        
        return text
    }
}
