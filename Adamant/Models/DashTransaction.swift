//
//  DashRawTransaction.swift
//  Adamant
//
//  Created by Anton Boyarkin on 19/05/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import Foundation

extension String.adamantLocalized {
    struct dashTransaction {
        static func recipients(_ recipients: Int) -> String {
            return String.localizedStringWithFormat(NSLocalizedString("Dash.TransactionDetails.RecipientsFormat", comment: "DashTransaction: amount of recipients, if more than one."), recipients)
        }
        
        static func senders(_ senders: Int) -> String {
            return String.localizedStringWithFormat(NSLocalizedString("Dash.TransactionDetails.SendersFormat", comment: "DashTransaction: amount of senders, if more than one."), senders)
        }
        
        private init() {}
    }
}

class DashTransaction: BaseBtcTransaction {
    override class var defaultCurrencySymbol: String? { return DashWalletService.currencySymbol }
}

struct BtcBlock: Decodable {
    let hash: String
    let height: Int64
    let time: Int64
    
    enum CodingKeys: String, CodingKey {
        case hash
        case height
        case time
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.hash = try container.decode(String.self, forKey: .hash)
        self.height = try container.decode(Int64.self, forKey: .height)
        self.time = try container.decode(Int64.self, forKey: .time)
    }
}
