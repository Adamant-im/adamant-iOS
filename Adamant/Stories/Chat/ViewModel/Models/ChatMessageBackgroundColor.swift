//
//  ChatBackgroundColor.swift
//  Adamant
//
//  Created by Andrey Golubenko on 08.02.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import UIKit

enum ChatMessageBackgroundColor: Equatable {
    case opponent
    case delivered
    case pending
    case failed
    
    var uiColor: UIColor {
        switch self {
        case .opponent:
            return .adamant.chatRecipientBackground
        case .delivered:
            return .adamant.chatSenderBackground
        case .pending:
            return .adamant.pendingChatBackground
        case .failed:
            return .adamant.failChatBackground
        }
    }
}
