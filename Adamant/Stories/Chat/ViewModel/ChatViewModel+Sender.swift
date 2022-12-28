//
//  ChatViewModel+Sender.swift
//  Adamant
//
//  Created by Andrey Golubenko on 23.12.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import MessageKit
import Foundation

extension ChatViewModel {
    struct Sender: SenderType {
        let senderId: String
        let displayName: String
        
        static let `default` = Self(senderId: "", displayName: "")
    }
}
