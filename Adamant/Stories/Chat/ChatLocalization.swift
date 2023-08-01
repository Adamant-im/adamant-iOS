//
//  Localization.swift
//  Adamant
//
//  Created by Andrey Golubenko on 29.12.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import Foundation
import CommonKit

// MARK: - Localization
extension String.adamant {
    enum chat {
        static let sendButton = String.localized("ChatScene.Send", comment: "Chat: Send message button")
        static let messageInputPlaceholder = String.localized("ChatScene.NewMessage.Placeholder", comment: "Chat: message input placeholder")
        static let cancelError = String.localized("ChatScene.Error.cancelError", comment: "Chat: inform user that he can't cancel transaction, that was sent")
        static let failToSend = String.localized("ChatScene.MessageStatus.FailToSend", comment: "Chat: status message for failed to send chat transaction")
        static let pending = String.localized("ChatScene.MessageStatus.Pending", comment: "Chat: status message for pending chat transaction")

        static let actionsBody = String.localized("ChatScene.Actions.Body", comment: "Chat: Body for actions menu")
        static let rename = String.localized("ChatScene.Actions.Rename", comment: "Chat: 'Rename' action in actions menu")
        static let name = String.localized("ChatScene.Actions.NamePlaceholder", comment: "Chat: 'Name' field in actions menu")

        static let noMailAppWarning = String.localized("ChatScene.Warning.NoMailApp", comment: "Chat: warning message for opening email link without mail app configurated on device")
        static let unsupportedUrlWarning = String.localized("ChatScene.Warning.UnsupportedUrl", comment: "Chat: warning message for opening unsupported url schemes")

        static let block = String.localized("Chats.Block", comment: "Block")

        static let remove = String.localized("Chats.Remove", comment: "Remove")
        static let removeMessage = String.localized("Chats.RemoveMessage", comment: "Delete this message?")
        static let report = String.localized("Chats.Report", comment: "Report")
        static let reply = String.localized("Chats.Reply", comment: "Reply")
        static let copy = String.localized("Chats.Copy", comment: "Copy")
        static let reportMessage = String.localized("Chats.ReportMessage", comment: "Report as inappropriate?")
        static let reportSent = String.localized("Chats.ReportSent", comment: "Report has been sent")

        static let freeTokens = String.localized("ChatScene.FreeTokensAlert.FreeTokens", comment: "Chat: 'Free Tokens' button")
        static let freeTokensMessage = String.localized("ChatScene.FreeTokensAlert.Message", comment: "Chat: 'Free Tokens' message")
        
        static let transactionSent = String.localized("ChatScene.Sent", comment: "Chat: 'Sent funds' bubble title")
        static let transactionReceived = String.localized("ChatScene.Received", comment: "Chat: 'Received funds' bubble title")
    }
}
