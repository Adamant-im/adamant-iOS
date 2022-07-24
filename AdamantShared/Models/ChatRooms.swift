//
//  ChatRooms.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 20.05.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import Foundation
struct ChatRooms : Codable {
    let chats : [ChatRoomsChats]?
    let messages : [Transaction]?
    let count : Int?
    
    enum CodingKeys: String, CodingKey {
        case chats = "chats"
        case count = "count"
        case messages = "messages"
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        chats = try values.decodeIfPresent([ChatRoomsChats].self, forKey: .chats)
        count = Int(try (values.decodeIfPresent(String.self, forKey: .count) ?? "0")) ?? 0
        messages = try values.decodeIfPresent([Transaction].self, forKey: .messages)
    }

}

extension ChatRooms: WrappableCollection {
    static let CollectionKey = "chatRooms"
}
