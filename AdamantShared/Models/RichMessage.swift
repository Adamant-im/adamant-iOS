//
//  RichMessage.swift
//  Adamant
//
//  Created by Anokhov Pavel on 29.08.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

// MARK: - RichMessage

protocol RichMessage: Codable {
    var type: String { get }
    var isReply: Bool { get }
    
    func content() -> [String:String]
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
}

// MARK: - RichMessageReply

struct RichMessageReply: RichMessage {
    var type: String
    var isReply: Bool
    var replyto_id: String
    var message: String
    var reply_message: String
    
    init(replyto_id: String, reply_message: String, message: String) {
        self.type = "reply"
        self.replyto_id = replyto_id
        self.message = message
        self.reply_message = reply_message
        self.isReply = true
    }
    
    func content() -> [String : String] {
        return [
            "replyto_id": replyto_id,
            "reply_message": reply_message,
            "message": message
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
    
    func content() -> [String:String] {
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
    struct transfer {
        static let amount = "amount"
        static let hash = "hash"
        static let comments = "comments"
        
        private init() {}
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
