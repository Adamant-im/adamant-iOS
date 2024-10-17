//
//  ChatRoomsChat.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 20.05.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import Foundation

public struct ChatRoomsChats : Codable, Sendable {
    public let lastTransaction : Transaction?
    
    public enum CodingKeys: String, CodingKey {
        case lastTransaction = "lastTransaction"
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        lastTransaction = try values.decodeIfPresent(Transaction.self, forKey: .lastTransaction)
    }
}
