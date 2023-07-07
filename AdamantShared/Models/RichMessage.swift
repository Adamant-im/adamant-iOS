//
//  RichMessage.swift
//  Adamant
//
//  Created by Anokhov Pavel on 29.08.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

// MARK: - RichMessage

protocol RichMessage: Encodable {
    var type: String { get }
    var isReply: Bool { get }
    
    func content() -> [String: Any]
    func serialized() -> String
}

extension RichMessage {
    func serialized() -> String {
        if let data = try? JSONEncoder().encode(self), let raw = String(data: data, encoding: String.Encoding.utf8) {
            return raw
        } else {
            return ""
        }
    }
}

struct RichContentKeys {
    static let type = "type"
    
    private init() {}
    
    enum reply {
        static let reply = "reply"
        static let replyToId = "replyto_id"
        static let replyMessage = "reply_message"
        static let decodedReplyMessage = "decodedMessage"
    }
    
    enum react {
        static let reactto_id = "reactto_id"
        static let react_message = "react_message"
    }
}

// MARK: - RichMessageReaction

struct RichMessageReaction: RichMessage {
    var type: String
    var isReply: Bool
    var reactto_id: String
    var react_message: String
    
    enum CodingKeys: String, CodingKey {
        case reactto_id, react_message
    }
    
    init(reactto_id: String, react_message: String) {
        self.type = RichContentKeys.reply.reply
        self.reactto_id = reactto_id
        self.react_message = react_message
        self.isReply = false
    }
    
    func content() -> [String: Any] {
        return [
            RichContentKeys.react.reactto_id: reactto_id,
            RichContentKeys.react.react_message: react_message
        ]
    }
}

// MARK: - RichMessageReply

struct RichMessageReply: RichMessage {
    var type: String
    var isReply: Bool
    var replyto_id: String
    var reply_message: String
    
    enum CodingKeys: String, CodingKey {
        case replyto_id, reply_message
    }
    
    init(replyto_id: String, reply_message: String) {
        self.type = RichContentKeys.reply.reply
        self.replyto_id = replyto_id
        self.reply_message = reply_message
        self.isReply = true
    }
    
    func content() -> [String: Any] {
        return [
            RichContentKeys.reply.replyToId: replyto_id,
            RichContentKeys.reply.replyMessage: reply_message
        ]
    }
}

struct RichTransferReply: RichMessage {
    var type: String
    var isReply: Bool
    var replyto_id: String
    var reply_message: [String: String]
    
    enum CodingKeys: String, CodingKey {
        case replyto_id, reply_message
    }
    
    init(
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
        self.isReply = true
    }
    
    func content() -> [String: Any] {
        return [
            RichContentKeys.reply.replyToId: replyto_id,
            RichContentKeys.reply.replyMessage: reply_message
        ]
    }
}

// MARK: - RichMessageTransfer

struct RichMessageTransfer: RichMessage {
    let type: String
    let amount: Decimal
    let hash: String
    let comments: String
    var isReply: Bool
    
    func content() -> [String: Any] {
        return [
            CodingKeys.type.stringValue: type,
            CodingKeys.amount.stringValue: RichMessageTransfer.serialize(balance: amount),
            CodingKeys.hash.stringValue: hash,
            CodingKeys.comments.stringValue: comments
        ]
    }
    
    init(type: String, amount: Decimal, hash: String, comments: String) {
        self.type = type
        self.amount = amount
        self.hash = hash
        self.comments = comments
        self.isReply = false
    }
    
    init?(content: [String: Any]) {
        if let content = content[RichContentKeys.reply.replyMessage] as? [String: String] {
            self.init(content: content)
        } else {
            guard let content = content as? [String: String] else {
                return nil
            }
            
            self.init(content: content)
        }
    }
    
    init?(content: [String:String]) {
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
        
        self.isReply = false
    }
}

extension RichContentKeys {
    enum transfer {
        static let amount = "amount"
        static let hash = "hash"
        static let comments = "comments"
    }
}

extension RichMessageTransfer {
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
        
        self.isReply = false
    }
}

extension RichMessageTransfer {
    static func serialize(balance: Decimal) -> String {
        return AdamantBalanceFormat.rawNumberDotFormatter.string(from: balance) ?? "0"
    }
}
