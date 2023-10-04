//
//  ChatItemStatus+Extension.swift
//  
//
//  Created by Andrew G on 09.10.2023.
//

import UIKit

extension ChatItemStatus {
    var backgroundColor: UIColor {
        switch self {
        case .received:
            return .adamant.chatRecipientBackground
        case .sent:
            return .adamant.chatSenderBackground
        case .pending:
            return .adamant.pendingChatBackground
        case .failed:
            return .adamant.failChatBackground
        }
    }
}
