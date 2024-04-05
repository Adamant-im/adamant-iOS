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
    enum shared {
        static var productName: String {
            String.localized("ADAMANT", comment: "Product name")
        }
    }
    
    enum alert {
        // MARK: Buttons
        static var cancel: String {
            String.localized("Shared.Cancel", comment: "Shared alert 'Cancel' button. Used anywhere")
        }
        static var ok: String {
            String.localized("Shared.Ok", comment: "Shared alert 'Ok' button. Used anywhere")
        }
        static var save: String {
            String.localized("Shared.Save", comment: "Shared alert 'Save' button. Used anywhere")
        }
        static var settings: String {
            String.localized("Shared.Settings", comment: "Shared alert 'Settings' button. Used to go to system Settings app, on application settings page. Should be same as Settings application title.")
        }
        static var retry: String {
            String.localized("Shared.Retry", comment: "Shared alert 'Retry' button. Used anywhere")
        }
        static var delete: String {
            String.localized("Shared.Delete", comment: "Shared alert 'Delete' button. Used anywhere")
        }
        
        // MARK: Titles and messages
        static var error: String {
            String.localized("Shared.Error", comment: "Shared alert 'Error' title. Used anywhere")
        }
        static var done: String {
            String.localized("Shared.Done", comment: "Shared alert Done message. Used anywhere")
        }
        static var retryOrDeleteTitle: String {
            String.localized("Chats.RetryOrDelete.Title", comment: "Alert 'Retry Or Delete' title. Used in caht for sending failed messages again or delete them")
        }
        static var retryOrDeleteBody: String {
            String.localized("Chats.RetryOrDelete.Body", comment: "Alert 'Retry Or Delete' body message. Used in caht for sending failed messages again or delete them")
        }
        
        // MARK: Notifications
        static var copiedToPasteboardNotification: String {
            String.localized("Shared.CopiedToPasteboard", comment: "Shared alert notification: message about item copied to pasteboard.")
        }
        static var noInternetNotificationTitle: String {
            String.localized("Shared.NoInternet.Title", comment: "Shared alert notification: title for no internet connection message.")
        }
        static var noInternetNotificationBoby: String {
            String.localized("Shared.NoInternet.Body", comment: "Shared alert notification: body message for no internet connection.")
        }
        static var noInternetTransferBody: String { String.localized("Shared.Transfer.NoInternet.Body", comment: "Shared alert notification: body message for no internet connection.")
        }
        
        static var emailErrorMessageTitle: String {
            String.localized("Error.Mail.Title", comment: "Error messge title for support email")
        }
        static var emailErrorMessageBody: String {
            String.localized("Error.Mail.Body", comment: "Error messge body for support email")
        }
        static var emailErrorMessageBodyWithDescription: String {
            String.localized("Error.Mail.Body.Detailed", comment: "Error messge body for support email, with detailed error description. Where first %@ - error's short message, second %@ - detailed description, third %@ - deviceInfo")
        }
    }
    
    enum sharedErrors {
        static var userNotLogged: String {
            String.localized("Error.UserNotLogged", comment: "Shared error: User not logged")
        }
        static var networkError: String {
            String.localized("Error.NoNetwork", comment: "Shared error: Network problems. In most cases - no connection")
        }
        static var requestCancelled: String {
            String.localized("Error.RequestCancelled", comment: "Shared error: Request cancelled")
        }
        static func commonError(_ text: String) -> String {
            String.localizedStringWithFormat(
                .localized(
                    "Error.BaseErrorFormat",
                    comment: "Shared error: Base format, %@"
                ),
                text
            )
        }
        
        static func accountNotFound(_ account: String) -> String {
            String.localizedStringWithFormat(.localized("Error.AccountNotFoundFormat", comment: "Shared error: Account not found error. Using %@ for address."), account)
        }
        
        static var accountNotInitiated: String {
            String.localized("Error.AccountNotInitiated", comment: "Shared error: Account not initiated")
        }
        
        static var unknownError: String {
            String.localized("Error.UnknownError", comment: "Shared unknown error")
        }
        static func admNodeErrorMessage(_ coin: String) -> String {
            String.localizedStringWithFormat(.localized("ApiService.InternalError.NoAdmNodesAvailable", comment: "No active ADM nodes to fetch the partner's %@ address"), coin)
        }
        
        static var notEnoughMoney: String {
            String.localized("WalletServices.SharedErrors.notEnoughMoney", comment: "Wallet Services: Shared error, user do not have enought money.")
        }
        
        static var dustError: String {
            String.localized("TransferScene.Dust.Error", comment: "Tranfser: Dust error.")
        }
        
        static var transactionUnavailable: String {
            String.localized("WalletServices.SharedErrors.transactionUnavailable", comment: "Wallet Services: Transaction unavailable")
        }
        
        static var inconsistentTransaction: String {
            String.localized("WalletServices.SharedErrors.inconsistentTransaction", comment: "Wallet Services: Cannot verify transaction")
        }
        
        static var walletFrezzed: String {
            String.localized("WalletServices.SharedErrors.walletFrezzed", comment: "Wallet Services: Wait until other transactions approved")
        }
        
        static func internalError(message: String) -> String {
            String.localizedStringWithFormat(.localized("Error.InternalErrorFormat", comment: "Shared error: Internal error format, %@ for message"), message)
        }
        
        static func remoteServerError(message: String) -> String {
            String.localizedStringWithFormat(.localized("Error.RemoteServerErrorFormat", comment: "Shared error: Remote error format, %@ for message"), message)
        }
    }
    
    enum reply {
        static var shortUnknownMessageError: String {
            String.localized("Reply.ShortUnknownMessageError", comment: "Short unknown message error")
        }
        static var longUnknownMessageError: String {
            String.localized("Reply.LongUnknownMessageError", comment: "Long unknown message error")
        }
        static var failedMessageError: String {
            String.localized("Reply.failedMessageError", comment: "Failed message reply error")
        }
        static var pendingMessageError: String {
            String.localized("Reply.pendingMessageError", comment: "Pending message reply error")
        }
    }
    
    enum partnerQR {
        static var includePartnerName: String {
            String.localized("PartnerQR.includePartnerName", comment: "Include partner name")
        }
        static var includePartnerURL: String {
            String.localized("PartnerQR.includePartnerURL", comment: "Include partner url")
        }
    }
}
