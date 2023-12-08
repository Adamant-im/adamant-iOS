//
//  String+localized.swift
//  Adamant
//
//  Created by Anokhov Pavel on 14.02.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import CommonKit

extension String.adamant {
    struct shared {
        static let productName = String.localized("ADAMANT", comment: "Product name")
        
        private init() {}
    }
    
    struct alert {
        // MARK: Buttons
        static let cancel = String.localized("Shared.Cancel", comment: "Shared alert 'Cancel' button. Used anywhere")
        static let ok = String.localized("Shared.Ok", comment: "Shared alert 'Ok' button. Used anywhere")
        static let save = String.localized("Shared.Save", comment: "Shared alert 'Save' button. Used anywhere")
        static let settings = String.localized("Shared.Settings", comment: "Shared alert 'Settings' button. Used to go to system Settings app, on application settings page. Should be same as Settings application title.")
        static let retry = String.localized("Shared.Retry", comment: "Shared alert 'Retry' button. Used anywhere")
        static let delete = String.localized("Shared.Delete", comment: "Shared alert 'Delete' button. Used anywhere")
        
        // MARK: Titles and messages
        static let error = String.localized("Shared.Error", comment: "Shared alert 'Error' title. Used anywhere")
        static let done = String.localized("Shared.Done", comment: "Shared alert Done message. Used anywhere")
        static let retryOrDeleteTitle = String.localized("Chats.RetryOrDelete.Title", comment: "Alert 'Retry Or Delete' title. Used in caht for sending failed messages again or delete them")
        static let retryOrDeleteBody = String.localized("Chats.RetryOrDelete.Body", comment: "Alert 'Retry Or Delete' body message. Used in caht for sending failed messages again or delete them")
        
        // MARK: Notifications
        static let copiedToPasteboardNotification = String.localized("Shared.CopiedToPasteboard", comment: "Shared alert notification: message about item copied to pasteboard.")
        
        static let noInternetNotificationTitle = String.localized("Shared.NoInternet.Title", comment: "Shared alert notification: title for no internet connection message.")
        static let noInternetNotificationBoby = String.localized("Shared.NoInternet.Body", comment: "Shared alert notification: body message for no internet connection.")
        static let noInternetTransferBody = String.localized("Shared.Transfer.NoInternet.Body", comment: "Shared alert notification: body message for no internet connection.")
        
        static let emailErrorMessageTitle = String.localized("Error.Mail.Title", comment: "Error messge title for support email")
        static let emailErrorMessageBody = String.localized("Error.Mail.Body", comment: "Error messge body for support email")
        static let emailErrorMessageBodyWithDescription = String.localized("Error.Mail.Body.Detailed", comment: "Error messge body for support email, with detailed error description. Where first %@ - error's short message, second %@ - detailed description, third %@ - deviceInfo")
    }
    
    struct sharedErrors {
        static let userNotLogged = String.localized("Error.UserNotLogged", comment: "Shared error: User not logged")
        static let networkError = String.localized("Error.NoNetwork", comment: "Shared error: Network problems. In most cases - no connection")
        static let requestCancelled = String.localized("Error.RequestCancelled", comment: "Shared error: Request cancelled")
        
        static func commonError(_ text: String) -> String {
            return String.localizedStringWithFormat(
                .localized(
                    "Error.BaseErrorFormat",
                    comment: "Shared error: Base format, %@"
                ),
                text
            )
        }
        
        static func accountNotFound(_ account: String) -> String {
            return String.localizedStringWithFormat(.localized("Error.AccountNotFoundFormat", comment: "Shared error: Account not found error. Using %@ for address."), account)
        }
        
        static let accountNotInitiated = String.localized("Error.AccountNotInitiated", comment: "Shared error: Account not initiated")
        
        static let unknownError = String.localized("Error.UnknownError", comment: "Shared unknown error")
        
        static let notEnoughMoney = String.localized("WalletServices.SharedErrors.notEnoughMoney", comment: "Wallet Services: Shared error, user do not have enought money.")
        
        static let dustError = String.localized("TransferScene.Dust.Error", comment: "Tranfser: Dust error.")
        
        static let transactionUnavailable = String.localized("WalletServices.SharedErrors.transactionUnavailable", comment: "Wallet Services: Transaction unavailable")
        
        static let inconsistentTransaction = String.localized("WalletServices.SharedErrors.inconsistentTransaction", comment: "Wallet Services: Cannot verify transaction")
        
        static let walletFrezzed = String.localized("WalletServices.SharedErrors.walletFrezzed", comment: "Wallet Services: Wait until other transactions approved")
        
        static func internalError(message: String) -> String {
            return String.localizedStringWithFormat(.localized("Error.InternalErrorFormat", comment: "Shared error: Internal error format, %@ for message"), message)
        }
        
        static func remoteServerError(message: String) -> String {
            return String.localizedStringWithFormat(.localized("Error.RemoteServerErrorFormat", comment: "Shared error: Remote error format, %@ for message"), message)
        }
    }
    
    enum reply {
        static let shortUnknownMessageError = String.localized("Reply.ShortUnknownMessageError", comment: "Short unknown message error")
        static let longUnknownMessageError = String.localized("Reply.LongUnknownMessageError", comment: "Long unknown message error")
        static let failedMessageError = String.localized("Reply.failedMessageError", comment: "Failed message reply error")
        static let pendingMessageError = String.localized("Reply.pendingMessageError", comment: "Pending message reply error")
    }
    
    enum partnerQR {
        static let includePartnerName = String.localized("PartnerQR.includePartnerName", comment: "Include partner name")
        static let includePartnerURL = String.localized("PartnerQR.includePartnerURL", comment: "Include partner url")
    }
}
