//
//  TransferType.swift
//  Adamant
//
//  Created by Anton Boyarkin on 22/06/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import web3swift
import BigInt

enum TransferType: String, Decodable {
    case eth = "eth_transaction"
    case lsk = "lsk_transaction"
    case unknown
    
    init(from decoder: Decoder) throws {
        let label = try decoder.singleValueContainer().decode(String.self)
        switch label {
        case "eth_transaction": self = .eth
        case "lsk_transaction": self = .lsk
        default: self = .unknown
        }
    }
}

struct ChatTransfer: Decodable {
    enum CodingKeys: String, CodingKey {
        case amount
        case hash
        case type
        case comments
    }
    let amount: String
    let hash: String
    let type: TransferType
    let comments: String
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        amount = (try? container.decode(String.self, forKey: .amount)) ?? "0"
        hash = (try? container.decode(String.self, forKey: .hash)) ?? ""
        type = (try? container.decode(TransferType.self, forKey: .type)) ?? .unknown
        comments = (try? container.decode(String.self, forKey: .comments)) ?? ""
    }
    
    func render() -> NSAttributedString {
        switch type {
        case .eth:
            return renderETH()
        case .lsk: return renderLSK()
        default:
            return NSAttributedString(string: "")
        }
    }
    
    func renderPreview(isOutgoing: Bool) -> String {
        switch type {
        case .eth:
            return renderETHPreview(isOutgoing: isOutgoing)
        case .lsk:
            return renderLSKPreview(isOutgoing: isOutgoing)
        default:
            return ""
        }
    }
    
    // MARK: - Chat renderers
    
    private func renderETH() -> NSAttributedString {
        guard let amount = BigUInt(amount) else {
            return NSAttributedString(string: "")
        }
        
        let balance: String
        
        if let formattedAmount = Web3.Utils.formatToEthereumUnits(amount,
                                                                  toUnits: .eth,
                                                                  decimals: 8,
                                                                  fallbackToScientific: true), let amount = Double(formattedAmount) {
            balance = "\(amount) ETH"
        } else {
            balance = "-- ETH"
        }
        
        let sent = String.adamantLocalized.chat.sent
        
        let attributedString = NSMutableAttributedString(string: "\(sent)\n\(balance)\n\n\(String.adamantLocalized.chat.tapForDetails)")
        
        let rangeReference = attributedString.string as NSString
        let sentRange = rangeReference.range(of: sent)
        let amountRange = rangeReference.range(of: balance)
        
        attributedString.setAttributes([.font: UIFont.adamantPrimary(size: 14)], range: sentRange)
        attributedString.setAttributes([.font: UIFont.adamantPrimary(size: 28)], range: amountRange)
        
        return attributedString
    }
    
    func renderLSK() -> NSAttributedString {
        guard let amount = BigUInt(amount) else {
            return NSAttributedString(string: "")
        }
        
        let balance: String
        
        if let formattedAmount = Web3.Utils.formatToPrecision(amount, numberDecimals: 8, formattingDecimals: 8), let amount = Double(formattedAmount) {
            balance = "\(amount) LSK"
        } else {
            balance = "-- LSK"
        }
        
        let sent = String.adamantLocalized.chat.sent
        
        let attributedString = NSMutableAttributedString(string: "\(sent)\n\(balance)\n\n\(String.adamantLocalized.chat.tapForDetails)")
        
        let rangeReference = attributedString.string as NSString
        let sentRange = rangeReference.range(of: sent)
        let amountRange = rangeReference.range(of: balance)
        
        attributedString.setAttributes([.font: UIFont.adamantPrimary(size: 14)], range: sentRange)
        attributedString.setAttributes([.font: UIFont.adamantPrimary(size: 28)], range: amountRange)
        
        return attributedString
    }
    
    // MARK: - Preview renderers
    
    func renderETHPreview(isOutgoing: Bool) -> String {
        guard let amount = BigUInt(amount) else {
            return ""
        }
        
        let balance: String
        
        if let formattedAmount = Web3.Utils.formatToEthereumUnits(amount,
                                                                  toUnits: .eth,
                                                                  decimals: 8,
                                                                  fallbackToScientific: true), let amount = Double(formattedAmount) {
            balance = "\(amount) ETH"
        } else {
            balance = "-- ETH"
        }
        
        if isOutgoing {
            return String.localizedStringWithFormat(String.adamantLocalized.chatList.sentMessagePrefix, " ⬅️  \(balance)")
        } else {
            return "➡️  \(balance)"
        }
    }
    
    func renderLSKPreview(isOutgoing: Bool) -> String {
        guard let amount = BigUInt(amount) else {
            return ""
        }
        
        let balance: String
        
        if let formattedAmount = Web3.Utils.formatToPrecision(amount, numberDecimals: 8, formattingDecimals: 8), let amount = Double(formattedAmount) {
            balance = "\(amount) LSK"
        } else {
            balance = "-- LSK"
        }
        
        if isOutgoing {
            return String.localizedStringWithFormat(String.adamantLocalized.chatList.sentMessagePrefix, " ⬅️  \(balance)")
        } else {
            return "➡️  \(balance)"
        }
    }
}
