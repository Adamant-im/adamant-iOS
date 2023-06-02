//
//  String+localized.swift
//  Adamant
//
//  Created by Anokhov Pavel on 14.02.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

extension String.adamantLocalized {
    struct shared {
        static let productName = NSLocalizedString("ADAMANT", comment: "Product name")
        
        private init() {}
    }
    
    struct alert {
        // MARK: Buttons
        static let cancel = NSLocalizedString("Shared.Cancel", comment: "Shared alert 'Cancel' button. Used anywhere")
        static let ok = NSLocalizedString("Shared.Ok", comment: "Shared alert 'Ok' button. Used anywhere")
        static let save = NSLocalizedString("Shared.Save", comment: "Shared alert 'Save' button. Used anywhere")
        static let settings = NSLocalizedString("Shared.Settings", comment: "Shared alert 'Settings' button. Used to go to system Settings app, on application settings page. Should be same as Settings application title.")
        static let retry = NSLocalizedString("Shared.Retry", comment: "Shared alert 'Retry' button. Used anywhere")
        static let delete = NSLocalizedString("Shared.Delete", comment: "Shared alert 'Delete' button. Used anywhere")
        
        // MARK: Titles and messages
        static let error = NSLocalizedString("Shared.Error", comment: "Shared alert 'Error' title. Used anywhere")
        static let done = NSLocalizedString("Shared.Done", comment: "Shared alert Done message. Used anywhere")
        static let retryOrDeleteTitle = NSLocalizedString("Chats.RetryOrDelete.Title", comment: "Alert 'Retry Or Delete' title. Used in caht for sending failed messages again or delete them")
        static let retryOrDeleteBody = NSLocalizedString("Chats.RetryOrDelete.Body", comment: "Alert 'Retry Or Delete' body message. Used in caht for sending failed messages again or delete them")
        
        // MARK: Notifications
        static let copiedToPasteboardNotification = NSLocalizedString("Shared.CopiedToPasteboard", comment: "Shared alert notification: message about item copied to pasteboard.")
        
        static let noInternetNotificationTitle = NSLocalizedString("Shared.NoInternet.Title", comment: "Shared alert notification: title for no internet connection message.")
        static let noInternetNotificationBoby = NSLocalizedString("Shared.NoInternet.Body", comment: "Shared alert notification: body message for no internet connection.")
        
        static let emailErrorMessageTitle = NSLocalizedString("Error.Mail.Title", comment: "Error messge title for support email")
        static let emailErrorMessageBody = NSLocalizedString("Error.Mail.Body", comment: "Error messge body for support email")
        static let emailErrorMessageBodyWithDescription = NSLocalizedString("Error.Mail.Body.Detailed", comment: "Error messge body for support email, with detailed error description. Where first %@ - error's short message, second %@ - detailed description, third %@ - deviceInfo")
    }
    
    struct sharedErrors {
        static let userNotLogged = NSLocalizedString("Error.UserNotLogged", comment: "Shared error: User not logged")
        static let networkError = NSLocalizedString("Error.NoNetwork", comment: "Shared error: Network problems. In most cases - no connection")
        static let requestCancelled = NSLocalizedString("Error.RequestCancelled", comment: "Shared error: Request cancelled")
        
        static func commonError(_ text: String) -> String {
            return String.localizedStringWithFormat(
                NSLocalizedString(
                    "Error.BaseErrorFormat",
                    comment: "Shared error: Base format, %@"
                ),
                text
            )
        }
        
        static func accountNotFound(_ account: String) -> String {
            return String.localizedStringWithFormat(NSLocalizedString("Error.AccountNotFoundFormat", comment: "Shared error: Account not found error. Using %@ for address."), account)
        }
        
        static let accountNotInitiated = NSLocalizedString("Error.AccountNotInitiated", comment: "Shared error: Account not initiated")
        
        static let unknownError = NSLocalizedString("Error.UnknownError", comment: "Shared unknown error")
        
        static let notEnoughMoney = NSLocalizedString("WalletServices.SharedErrors.notEnoughMoney", comment: "Wallet Services: Shared error, user do not have enought money.")
        
        static let dustError = NSLocalizedString("TransferScene.Dust.Error", comment: "Tranfser: Dust error.")
        
        static let transactionUnavailable = NSLocalizedString("WalletServices.SharedErrors.transactionUnavailable", comment: "Wallet Services: Transaction unavailable")
        
        static let inconsistentTransaction = NSLocalizedString("WalletServices.SharedErrors.inconsistentTransaction", comment: "Wallet Services: Cannot verify transaction")
        
        static let walletFrezzed = NSLocalizedString("WalletServices.SharedErrors.walletFrezzed", comment: "Wallet Services: Wait until other transactions approved")
        
        static func internalError(message: String) -> String {
            return String.localizedStringWithFormat(NSLocalizedString("Error.InternalErrorFormat", comment: "Shared error: Internal error format, %@ for message"), message)
        }
        
        static func remoteServerError(message: String) -> String {
            return String.localizedStringWithFormat(NSLocalizedString("Error.RemoteServerErrorFormat", comment: "Shared error: Remote error format, %@ for message"), message)
        }
    }
    
    enum reply {
        static let shortUnknownMessageError = NSLocalizedString("Reply.ShortUnknownMessageError", comment: "Short unknown message error")
        static let longUnknownMessageError = NSLocalizedString("Reply.LongUnknownMessageError", comment: "Long unknown message error")
        static let failedMessageError = NSLocalizedString("Reply.failedMessageError", comment: "Failed message reply error")
        static let pendingMessageError = NSLocalizedString("Reply.pendingMessageError", comment: "Pending message reply error")
    }
}
