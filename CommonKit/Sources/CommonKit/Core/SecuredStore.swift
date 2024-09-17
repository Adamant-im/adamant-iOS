//
//  SecuredStore.swift
//  Adamant
//
//  Created by Anokhov Pavel on 04.03.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

// For extensions in other classes
public enum StoreKey {}

// MARK: - Notifications

public extension Notification.Name {
    enum SecuredStore {
        /// Raised when store is purged
        public static let securedStorePurged = Notification.Name("adamant.SecuredStore.purged")
    }
}

public extension StoreKey {
    enum notificationsService {
        public static let notificationsMode = "notifications.mode"
        public static let customBadgeNumber = "notifications.number"
        public static let notificationsSound = "notifications.sound"
        public static let notificationsReactionSound = "notifications.reaction.sound"
        public static let inAppSounds = "notifications.inAppSounds"
        public static let inAppVibrate = "notifications.inAppVibrate"
        public static let inAppToasts = "notifications.inAppToasts"
    }
    
    enum visibleWallets {
        public static let invisibleWallets = "invisible.wallets"
        public static let indexWallets = "index.wallets"
        public static let indexWalletsWithInvisible = "index.wallets.include.ivisible"
        public static let useCustomIndexes = "visible.wallets.useCustomIndexes"
        public static let useCustomVisibility = "visible.wallets.useCustomVisibility"
    }
    
    enum increaseFee {
        public static let increaseFee = "increaseFee"
    }
    
    enum crashlytic {
        public static let crashlyticEnabled = "crashlyticEnabled"
    }
    
    enum emojis {
        public static let emojis = "emojis"
    }
    
    enum partnerQR {
        public static let includeNameEnabled = "includeNameEnabled"
        public static let includeURLEnabled = "includeURLEnabled"
    }
    
    enum language {
        public static let language = "language"
        public static let languageLocale = "language.locale"
    }
    
    enum storage {
        public static let autoDownloadPreview = "autoDownloadPreviewEnabled"
        public static let autoDownloadFullMedia = "autoDownloadFullMediaEnabled"
        public static let saveFileEncrypted = "saveFileEncrypted"
    }
}

public protocol SecuredStore: AnyObject {
    func get<T: Decodable>(_ key: String) -> T?
    func set<T: Encodable>(_ value: T, for key: String)

    func remove(_ key: String)
    
    /// Remove everything
    func purgeStore()
}
