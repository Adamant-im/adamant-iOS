//
//  String+utilites.swift
//  Adamant
//
//  Created by Anokhov Pavel on 22/05/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import Foundation

extension String {
    func toDictionary() -> [String: Any]? {
        if let data = self.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
    
    func matches(for regex: String) -> [String] {
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let results = regex.matches(in: self, range: NSRange(self.startIndex..., in: self))
            
            return results.map {
                String(self[Range($0.range, in: self)!])
            }
        } catch let error {
            print("invalid regex: \(error.localizedDescription)")
            return []
        }
    }
    
    subscript (i: Int) -> Character {
        return self[index(startIndex, offsetBy:i)]
    }
}

extension String {
    func checkAndReplaceSystemWallets() -> String {
        switch self {
        case "chats.virtual.bounty_wallet_title":
            return AdamantContacts.adamantNewBountyWallet.name
        case "chats.virtual.bitcoin_bet_title":
            return AdamantContacts.betOnBitcoin.name
        case "chats.virtual.donate_bot_title":
            return AdamantContacts.donate.name
        case "chats.virtual.exchange_bot_title":
            return AdamantContacts.adamantExchange.name
        default:
            return self
        }
    }
}
