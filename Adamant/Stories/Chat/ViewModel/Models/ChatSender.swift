//
//  ChatSender.swift
//  Adamant
//
//  Created by Andrey Golubenko on 12.01.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import MessageKit

struct ChatSender: SenderType, Equatable {
    let senderId: String
    let displayName: String
    
    static let `default` = Self(senderId: "", displayName: "")
}
