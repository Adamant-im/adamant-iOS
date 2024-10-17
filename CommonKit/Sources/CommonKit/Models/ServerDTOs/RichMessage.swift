//
//  RichMessage.swift
//  Adamant
//
//  Created by Anokhov Pavel on 29.08.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

// MARK: - RichMessage

public protocol RichMessage: Encodable, Sendable {
    var type: String { get }
    var additionalType: RichAdditionalType { get }
    
    func content() -> [String: Any]
    func serialized() -> String
}

extension RichMessage {
    public func serialized() -> String {
        if let data = try? JSONEncoder().encode(self), let raw = String(data: data, encoding: String.Encoding.utf8) {
            return raw
        } else {
            return ""
        }
    }
}

public enum RichContentKeys {
    public static let type = "type"
    public static let hash = "hash"
    
    public enum reply {
        public static let reply = "reply"
        public static let replyToId = "replyto_id"
        public static let replyMessage = "reply_message"
        public static let decodedReplyMessage = "decodedMessage"
    }
    
    public enum react {
        public static let react = "react"
        public static let reactto_id = "reactto_id"
        public static let react_message = "react_message"
        public static let reactions = "reactions"
    }
    
    public enum file {
        public static let file = "file"
        public static let files = "files"
        public static let file_id = "file_id"
        public static let comment = "comment"
        public static let storage = "storage"
        public static let nonce = "nonce"
        public static let resolution = "resolution"
        public static let id = "id"
        public static let size = "size"
        public static let type = "type"
        public static let name = "name"
        public static let preview = "preview"
        public static let `extension` = "extension"
        public static let duration = "duration"
        public static let mimeType = "mimeType"
    }
}

// MARK: - RichMessageReaction

public struct RichMessageReaction: RichMessage, @unchecked Sendable {
    public var type: String
    public var additionalType: RichAdditionalType
    public var reactto_id: String
    public var react_message: String
    
    public enum CodingKeys: String, CodingKey {
        case reactto_id, react_message
    }
    
    public init(reactto_id: String, react_message: String) {
        self.type = RichContentKeys.reply.reply
        self.reactto_id = reactto_id
        self.react_message = react_message
        self.additionalType = .reaction
    }
    
    public func content() -> [String: Any] {
        return [
            RichContentKeys.react.reactto_id: reactto_id,
            RichContentKeys.react.react_message: react_message
        ]
    }
}

// MARK: - RichMessageFile

public struct RichMessageFile: RichMessage, @unchecked Sendable {
    public struct Preview: Codable, Equatable, Hashable {
        public var id: String
        public var nonce: String
        public var `extension`: String?
        
        public init(
            id: String,
            nonce: String,
            extension: String?
        ) {
            self.id = id
            self.nonce = nonce
            self.extension = `extension`
        }
        
        public init(_ data: [String: Any]) {
            self.id = (data[RichContentKeys.file.id] as? String) ?? .empty
            self.nonce = data[RichContentKeys.file.nonce] as? String ?? .empty
            self.extension = data[RichContentKeys.file.extension] as? String ?? .empty
        }
        
        public func content() -> [String: Any] {
            var contentDict: [String : Any] =  [:]
            
            if !id.isEmpty {
                contentDict[RichContentKeys.file.id] = id
            }
            
            if !nonce.isEmpty {
                contentDict[RichContentKeys.file.nonce] = nonce
            }
            
            if !nonce.isEmpty {
                contentDict[RichContentKeys.file.extension] = `extension`
            }
            
            return contentDict
        }
    }
    
    public struct File: Codable, Equatable, Hashable {
        public var preview: Preview?
        public var id: String
        public var `extension`: String?
        public var mimeType: String?
        public var size: Int64
        public var nonce: String
        public var resolution: CGSize?
        public var name: String?
        public var duration: Float64?
        
        public init(
            id: String,
            size: Int64,
            nonce: String,
            name: String?,
            `extension`: String? = nil,
            mimeType: String? = nil,
            preview: Preview? = nil,
            resolution: CGSize? = nil,
            duration: Float64? = nil
        ) {
            self.id = id
            self.extension = `extension`
            self.mimeType = mimeType
            self.size = size
            self.nonce = nonce
            self.name = name
            self.preview = preview
            self.resolution = resolution
            self.duration = duration
        }
        
        public init(_ data: [String: Any]) {
            self.id = (data[RichContentKeys.file.id] as? String) ?? .empty
            self.`extension` = data[RichContentKeys.file.extension] as? String
            ?? data[RichContentKeys.file.type] as? String
            self.size = (data[RichContentKeys.file.size] as? Int64) ?? .zero
            self.name = data[RichContentKeys.file.name] as? String
            self.nonce = data[RichContentKeys.file.nonce] as? String ?? .empty
            self.duration = data[RichContentKeys.file.duration] as? Float64
            self.mimeType = data[RichContentKeys.file.mimeType] as? String
            
            if let previewData = data[RichContentKeys.file.preview] as? [String: Any] {
                self.preview = Preview(previewData)
            }
            
            if let resolution = data[RichContentKeys.file.resolution] as? [CGFloat] {
                self.resolution = .init(
                    width: resolution.first ?? .zero,
                    height: resolution.last ?? .zero
                )
            } else if let resolution = data[RichContentKeys.file.resolution] as? CGSize {
                self.resolution = resolution
            } else {
                self.resolution = nil
            }
        }
        
        public func content() -> [String: Any] {
            var contentDict: [String : Any] =  [
                RichContentKeys.file.id: id,
                RichContentKeys.file.size: size,
                RichContentKeys.file.nonce: nonce
            ]
            
            if let value = `extension`, !value.isEmpty {
                contentDict[RichContentKeys.file.extension] = value
            }
            
            if let preview = preview {
                contentDict[RichContentKeys.file.preview] = preview.content()
            }
            
            if let name = name, !name.isEmpty {
                contentDict[RichContentKeys.file.name] = name
            }
            
            if let resolution = resolution {
                contentDict[RichContentKeys.file.resolution] = resolution
            }
            
            if let duration = duration {
                contentDict[RichContentKeys.file.duration] = duration
            }
            
            if let mimeType = mimeType {
                contentDict[RichContentKeys.file.mimeType] = mimeType
            }
            
            return contentDict
        }
    }
    
    public struct Storage: Codable, Equatable, Hashable {
        public var id: String
        
        public init(id: String) {
            self.id = id
        }
        
        public init(_ data: [String: Any]) {
            self.id = (data[RichContentKeys.file.id] as? String) ?? .empty
        }
        
        public func content() -> [String: Any] {
            let contentDict: [String : Any] =  [
                RichContentKeys.file.id: id
            ]
            
            return contentDict
        }
    }
    
    public var type: String
    public var additionalType: RichAdditionalType
    public var files: [File]
    public var storage: Storage
    public var comment: String?
    
    public enum CodingKeys: String, CodingKey {
        case files, storage, comment
    }
    
    public init(files: [File], storage: Storage, comment: String?) {
        self.type = RichContentKeys.file.file
        self.files = files
        self.storage = storage
        self.comment = comment
        self.additionalType = .file
    }
    
    public func content() -> [String: Any] {
        var contentDict: [String : Any] = [
            RichContentKeys.file.files: files.map { $0.content() },
            RichContentKeys.file.storage: storage.content()
        ]
        
        if let comment = comment, !comment.isEmpty {
            contentDict[RichContentKeys.file.comment] = comment
        }
        return contentDict
    }
}

public struct RichFileReply: RichMessage, @unchecked Sendable {
    public var type: String
    public var additionalType: RichAdditionalType
    public var replyto_id: String
    public var reply_message: RichMessageFile
    
    public enum CodingKeys: String, CodingKey {
        case replyto_id, reply_message
    }
    
    public init(replyto_id: String, reply_message: RichMessageFile) {
        self.type = RichContentKeys.reply.reply
        self.replyto_id = replyto_id
        self.reply_message = reply_message
        self.additionalType = .reply
    }
    
    public func content() -> [String: Any] {
        return [
            RichContentKeys.reply.replyToId: replyto_id,
            RichContentKeys.reply.replyMessage: reply_message.content()
        ]
    }
}

// MARK: - RichMessageReply

public struct RichMessageReply: RichMessage, @unchecked Sendable {
    public var type: String
    public var additionalType: RichAdditionalType
    public var replyto_id: String
    public var reply_message: String
    
    public enum CodingKeys: String, CodingKey {
        case replyto_id, reply_message
    }
    
    public init(replyto_id: String, reply_message: String) {
        self.type = RichContentKeys.reply.reply
        self.replyto_id = replyto_id
        self.reply_message = reply_message
        self.additionalType = .reply
    }
    
    public func content() -> [String: Any] {
        return [
            RichContentKeys.reply.replyToId: replyto_id,
            RichContentKeys.reply.replyMessage: reply_message
        ]
    }
}

public struct RichTransferReply: RichMessage, @unchecked Sendable {
    public var type: String
    public var additionalType: RichAdditionalType
    public var replyto_id: String
    public var reply_message: [String: String]
    
    public enum CodingKeys: String, CodingKey {
        case replyto_id, reply_message
    }
    
    public init(
        replyto_id: String,
        type: String,
        amount: Decimal,
        hash: String,
        comments: String
    ) {
        self.type = type
        self.replyto_id = replyto_id
        self.reply_message = [
            RichMessageTransfer.CodingKeys.type.stringValue: type,
            RichMessageTransfer.CodingKeys.amount.stringValue: RichMessageTransfer.serialize(balance: amount),
            RichMessageTransfer.CodingKeys.hash.stringValue: hash,
            RichMessageTransfer.CodingKeys.comments.stringValue: comments
        ]
        self.additionalType = .reply
    }
    
    public func content() -> [String: Any] {
        return [
            RichContentKeys.reply.replyToId: replyto_id,
            RichContentKeys.reply.replyMessage: reply_message
        ]
    }
}

// MARK: - RichMessageTransfer

public struct RichMessageTransfer: RichMessage, @unchecked Sendable {
    public let type: String
    public let amount: Decimal
    public let hash: String
    public let comments: String
    public var additionalType: RichAdditionalType
    
    public func content() -> [String: Any] {
        return [
            CodingKeys.type.stringValue: type,
            CodingKeys.amount.stringValue: RichMessageTransfer.serialize(balance: amount),
            CodingKeys.hash.stringValue: hash,
            CodingKeys.comments.stringValue: comments
        ]
    }
    
    public init(type: String, amount: Decimal, hash: String, comments: String) {
        self.type = type
        self.amount = amount
        self.hash = hash
        self.comments = comments
        self.additionalType = .base
    }
    
    public init?(content: [String: Any]) {
        var newContent = content
        
        if let content = content[RichContentKeys.reply.replyMessage] as? [String: String] {
            self.init(content: content)
        } else {
            newContent[RichContentKeys.react.reactions] = ""
            
            guard let content = newContent as? [String: String] else {
                return nil
            }
            
            self.init(content: content)
        }
    }
    
    public init?(content: [String:String]) {
        guard let type = content[CodingKeys.type.stringValue] else {
            return nil
        }
        
        guard let hash = content[CodingKeys.hash.stringValue] else {
            return nil
        }
        
        self.type = type
        self.hash = hash
        
        if let raw = content[CodingKeys.amount.stringValue] {
            // NumberFormatter.number(from: string).decimalValue loses precision.
            
            if let number = Decimal(string: raw), number != 0.0 {
                self.amount = number
            } else if let number = Decimal(string: raw, locale: Locale.current), number != 0.0 {
                self.amount = number
            } else if let number = AdamantBalanceFormat.rawNumberDotFormatter.number(from: raw) {
                self.amount = number.decimalValue
            } else if let number = AdamantBalanceFormat.rawNumberCommaFormatter.number(from: raw) {
                self.amount = number.decimalValue
            } else {
                self.amount = 0
            }
        } else {
            self.amount = 0
        }
        
        if let comments = content[CodingKeys.comments.stringValue] {
            self.comments = comments
        } else {
            self.comments = ""
        }
        
        self.additionalType = .base
    }
}

public extension RichContentKeys {
    enum transfer {
        public static let amount = "amount"
        public static let hash = "hash"
        public static let comments = "comments"
    }
}

public extension RichMessageTransfer {
    enum CodingKeys: String, CodingKey {
        case type, amount, hash, comments
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(hash, forKey: .hash)
        try container.encode(comments, forKey: .comments)
        try container.encode(amount, forKey: .amount)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.type = try container.decode(String.self, forKey: .type)
        self.hash = try container.decode(String.self, forKey: .hash)
        self.comments = try container.decode(String.self, forKey: .comments)
        
        if let raw = try? container.decode(String.self, forKey: .amount) {
            if let balance = AdamantBalanceFormat.deserializeBalance(from: raw) {
                self.amount = balance
            } else {
                self.amount = 0
            }
        } else if let amount = try? container.decode(Decimal.self, forKey: .amount) {
            self.amount = amount
        } else {
            self.amount = 0
        }
        
        self.additionalType = .base
    }
}

public extension RichMessageTransfer {
    static func serialize(balance: Decimal) -> String {
        return AdamantBalanceFormat.rawNumberDotFormatter.string(from: balance) ?? "0"
    }
}
