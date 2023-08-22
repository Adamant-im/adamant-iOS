//
//  RichMessage.swift
//  Adamant
//
//  Created by Anokhov Pavel on 29.08.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

// MARK: - RichMessage

public protocol RichMessage: Encodable {
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
}

// MARK: - RichMessageReaction

public struct RichMessageReaction: RichMessage {
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

// MARK: - RichMessageReply

public struct RichMessageReply: RichMessage {
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

public struct RichTransferReply: RichMessage {
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

public struct RichMessageTransfer: RichMessage {
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
