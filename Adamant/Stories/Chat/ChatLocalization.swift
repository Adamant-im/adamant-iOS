//
//  Localization.swift
//  Adamant
//
//  Created by Andrey Golubenko on 29.12.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import Foundation

// MARK: - Localization
extension String.adamantLocalized {
    enum chat {
        static let sendButton = NSLocalizedString("ChatScene.Send", comment: "Chat: Send message button")
        static let messageInputPlaceholder = NSLocalizedString("ChatScene.NewMessage.Placeholder", comment: "Chat: message input placeholder")
        static let cancelError = NSLocalizedString("ChatScene.Error.cancelError", comment: "Chat: inform user that he can't cancel transaction, that was sent")
        static let failToSend = NSLocalizedString("ChatScene.MessageStatus.FailToSend", comment: "Chat: status message for failed to send chat transaction")
        static let pending = NSLocalizedString("ChatScene.MessageStatus.Pending", comment: "Chat: status message for pending chat transaction")

        static let actionsBody = NSLocalizedString("ChatScene.Actions.Body", comment: "Chat: Body for actions menu")
        static let rename = NSLocalizedString("ChatScene.Actions.Rename", comment: "Chat: 'Rename' action in actions menu")
        static let name = NSLocalizedString("ChatScene.Actions.NamePlaceholder", comment: "Chat: 'Name' field in actions menu")

        static let noMailAppWarning = NSLocalizedString("ChatScene.Warning.NoMailApp", comment: "Chat: warning message for opening email link without mail app configurated on device")
        static let unsupportedUrlWarning = NSLocalizedString("ChatScene.Warning.UnsupportedUrl", comment: "Chat: warning message for opening unsupported url schemes")

        static let block = NSLocalizedString("Chats.Block", comment: "Block")

        static let remove = NSLocalizedString("Chats.Remove", comment: "Remove")
        static let removeMessage = NSLocalizedString("Chats.RemoveMessage", comment: "Delete this message?")
        static let report = NSLocalizedString("Chats.Report", comment: "Report")
        static let reply = NSLocalizedString("Chats.Reply", comment: "Reply")
        static let copy = NSLocalizedString("Chats.Copy", comment: "Copy")
        static let reportMessage = NSLocalizedString("Chats.ReportMessage", comment: "Report as inappropriate?")
        static let reportSent = NSLocalizedString("Chats.ReportSent", comment: "Report has been sent")

        static let freeTokens = NSLocalizedString("ChatScene.FreeTokensAlert.FreeTokens", comment: "Chat: 'Free Tokens' button")
        static let freeTokensMessage = NSLocalizedString("ChatScene.FreeTokensAlert.Message", comment: "Chat: 'Free Tokens' message")
        
        static let transactionSent = NSLocalizedString("ChatScene.Sent", comment: "Chat: 'Sent funds' bubble title")
        static let transactionReceived = NSLocalizedString("ChatScene.Received", comment: "Chat: 'Received funds' bubble title")
    }
}
