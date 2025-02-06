//
//  AdamantLocalized.swift
//  Adamant
//
//  Created by Anokhov Pavel on 30/05/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import Foundation

public protocol Localizable {
    var localized: String { get }
}

extension String: Localizable {
    public var localized: String {
        .localized(self, comment: "")
    }
}

public extension String {
    enum adamant {}
    
    static func locale() -> Locale {
        guard let languageRaw = UserDefaults.standard.string(forKey: StoreKey.language.language),
              !languageRaw.isEmpty,
              languageRaw != Language.auto.rawValue
        else {
            return .current
        }
        
        return Locale(identifier: languageRaw)
    }
    
    static func localized(_ key: String, comment: String = .empty) -> String {
        guard let languageRaw = UserDefaults.standard.string(forKey: StoreKey.language.language),
              !languageRaw.isEmpty,
              languageRaw != Language.auto.rawValue,
              let path = Bundle.module.path(forResource: languageRaw, ofType: "lproj")
        else {
            return NSLocalizedString(key, bundle: .module, comment: comment)
        }
        
        let bundle: Bundle = Bundle(path: path) ?? .module
        return NSLocalizedString(key, bundle: bundle, comment: comment)
    }
}

public extension String.adamant {
    enum shared {
        public static var productName: String {
            String.localized("ADAMANT", comment: "Product name")
        }
    }
    
    enum sharedErrors {
        public static var userNotLogged: String {
            String.localized("Error.UserNotLogged", comment: "Shared error: User not logged")
        }
        public static var networkError: String {
            String.localized("Error.NoNetwork", comment: "Shared error: Network problems. In most cases - no connection")
        }
        public static var timeoutError: String {
            String.localized("Error.TimeOut", comment: "Shared error: Timeout Problem. In most cases - no connection")
        }
        public static var requestCancelled: String {
            String.localized("Error.RequestCancelled", comment: "Shared error: Request cancelled")
        }
        public static func commonError(_ text: String) -> String {
            String.localizedStringWithFormat(
                .localized(
                    "Error.BaseErrorFormat",
                    comment: "Shared error: Base format, %@"
                ),
                text
            )
        }
        
        public static func accountNotFound(_ account: String) -> String {
            String.localizedStringWithFormat(.localized("Error.AccountNotFoundFormat", comment: "Shared error: Account not found error. Using %@ for address."), account)
        }
        
        public static var accountNotInitiated: String {
            String.localized("Error.AccountNotInitiated", comment: "Shared error: Account not initiated")
        }
        
        public static var unknownError: String {
            String.localized("Error.UnknownError", comment: "Shared unknown error")
        }
        public static func admNodeErrorMessage(_ coin: String) -> String {
            String.localizedStringWithFormat(.localized("ApiService.InternalError.NoAdmNodesAvailable", comment: "No active ADM nodes to fetch the partner's %@ address"), coin)
        }
        
        public static var notEnoughMoney: String {
            String.localized("WalletServices.SharedErrors.notEnoughMoney", comment: "Wallet Services: Shared error, user do not have enought money.")
        }
        
        public static var dustError: String {
            String.localized("TransferScene.Dust.Error", comment: "Tranfser: Dust error.")
        }
        
        public static var transactionUnavailable: String {
            String.localized("WalletServices.SharedErrors.transactionUnavailable", comment: "Wallet Services: Transaction unavailable")
        }
        
        public static var inconsistentTransaction: String {
            String.localized("WalletServices.SharedErrors.inconsistentTransaction", comment: "Wallet Services: Cannot verify transaction")
        }
        
        public static var walletFrezzed: String {
            String.localized("WalletServices.SharedErrors.walletFrezzed", comment: "Wallet Services: Wait until other transactions approved")
        }
        
        public static func internalError(message: String) -> String {
            String.localizedStringWithFormat(.localized("Error.InternalErrorFormat", comment: "Shared error: Internal error format, %@ for message"), message)
        }
        
        public static func remoteServerError(message: String) -> String {
            String.localizedStringWithFormat(.localized("Error.RemoteServerErrorFormat", comment: "Shared error: Remote error format, %@ for message"), message)
        }
    }
}
