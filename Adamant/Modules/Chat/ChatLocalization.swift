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
        static var sendButton: String {
            String.localized("ChatScene.Send", comment: "Chat: Send message button")
        }
        static var messageInputPlaceholder: String {
            String.localized("ChatScene.NewMessage.Placeholder", comment: "Chat: message input placeholder")
        }
        static var cancelError: String {
            String.localized("ChatScene.Error.cancelError", comment: "Chat: inform user that he can't cancel transaction, that was sent")
        }
        static var failToSend: String {
            String.localized("ChatScene.MessageStatus.FailToSend", comment: "Chat: status message for failed to send chat transaction")
        }
        static var pending: String {
            String.localized("ChatScene.MessageStatus.Pending", comment: "Chat: status message for pending chat transaction")
        }
        static var actionsBody: String {
            String.localized("ChatScene.Actions.Body", comment: "Chat: Body for actions menu")
        }
        static var rename: String {
            String.localized("ChatScene.Actions.Rename", comment: "Chat: 'Rename' action in actions menu")
        }
        static var name: String {
            String.localized("ChatScene.Actions.NamePlaceholder", comment: "Chat: 'Name' field in actions menu")
        }
        static var noMailAppWarning: String {
            String.localized("ChatScene.Warning.NoMailApp", comment: "Chat: warning message for opening email link without mail app configurated on device")
        }
        static var unsupportedUrlWarning: String {
            String.localized("ChatScene.Warning.UnsupportedUrl", comment: "Chat: warning message for opening unsupported url schemes")
        }
        static var block: String {
            String.localized("Chats.Block", comment: "Block")
        }
        static var remove: String {
            String.localized("Chats.Remove", comment: "Remove")
        }
        static var removeMessage: String {
            String.localized("Chats.RemoveMessage", comment: "Delete this message?")
        }
        static var report: String {
            String.localized("Chats.Report", comment: "Report")
        }
        static var selectText: String {
            String.localized("Chats.SelectText", comment: "Select Text")
        }
        static var reply: String {
            String.localized("Chats.Reply", comment: "Reply")
        }
        static var copy: String {
            String.localized("Chats.Copy", comment: "Copy")
        }
        static var reportMessage: String {
            String.localized("Chats.ReportMessage", comment: "Report as inappropriate?")
        }
        static var reportSent: String {
            String.localized("Chats.ReportSent", comment: "Report has been sent")
        }
        static var freeTokens: String {
            String.localized("ChatScene.FreeTokensAlert.FreeTokens", comment: "Chat: 'Free Tokens' button")
        }
        static var freeTokensMessage: String {
            String.localized("ChatScene.FreeTokensAlert.Message", comment: "Chat: 'Free Tokens' message")
        }
        static var transactionSent: String {
            String.localized("ChatScene.Sent", comment: "Chat: 'Sent funds' bubble title")
        }
        static var transactionReceived: String {
            String.localized("ChatScene.Received", comment: "Chat: 'Received funds' bubble title")
        }
        static var messageWasDeleted: String {
            String.localized("ChatScene.Error.messageWasDeleted", comment: "Chat: Error scrolling to message, this message has been deleted and is no longer accessible")
        }
        static var messageIsTooBig: String {
            String.localized("ChatScene.Error.messageIsTooBig", comment: "Chat: Error message is too big")
        }
    }
}
