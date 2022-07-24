//
//  ChatRoomsChat.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 20.05.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import Foundation

struct ChatRoomsChats : Codable {
    
    let lastTransaction : Transaction?
    
    enum CodingKeys: String, CodingKey {
        case lastTransaction = "lastTransaction"
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        lastTransaction = try values.decodeIfPresent(Transaction.self, forKey: .lastTransaction)
    }

}
