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
    
    var currencySymbol: String {
        switch self {
        case .eth: return "ETH"
        case .lsk: return "LSK"
        default: return ""
        }
    }
}

struct ChatTransfer {
	let amount: String
    let hash: String
    let type: TransferType
    let comments: String
	
    func render() -> NSAttributedString {
        guard type != .unknown else {
            return NSAttributedString(string: "")
        }
        
        let balance = "\(amount) \(type.currencySymbol)"
        
        let sent = String.adamantLocalized.chat.sent
        
        let attributedString = NSMutableAttributedString(string: "\(sent)\n\(balance)")
        
        if comments != "" {
            attributedString.append(NSAttributedString(string: "\n\(comments)"))
        }
        
        attributedString.append(NSAttributedString(string: "\n\n\(String.adamantLocalized.chat.tapForDetails)"))
        
        let rangeReference = attributedString.string as NSString
        let sentRange = rangeReference.range(of: sent)
        let amountRange = rangeReference.range(of: balance)
        
        attributedString.setAttributes([.font: UIFont.adamantPrimary(ofSize: 14)], range: sentRange)
        attributedString.setAttributes([.font: UIFont.adamantPrimary(ofSize: 28)], range: amountRange)
        
        return attributedString
    }
    
    func renderPreview(isOutgoing: Bool) -> String {
        let balance = "\(amount) \(type.currencySymbol)"
        
        if isOutgoing {
            return String.localizedStringWithFormat(String.adamantLocalized.chatList.sentMessagePrefix, " ⬅️  \(balance)")
        } else {
            return "➡️  \(balance)"
        }
    }
}

extension ChatTransfer: Decodable {
	enum CodingKeys: String, CodingKey {
		case amount
		case hash
		case type
		case comments
	}
	
	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		
		amount = (try? container.decode(String.self, forKey: .amount)) ?? "0"
		hash = (try? container.decode(String.self, forKey: .hash)) ?? ""
		type = (try? container.decode(TransferType.self, forKey: .type)) ?? .unknown
		comments = (try? container.decode(String.self, forKey: .comments)) ?? ""
	}
}
