//
//  SecuredStore.swift
//  Adamant
//
//  Created by Anokhov Pavel on 04.03.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

// For extensions in other classes
struct StoreKey {
    private init() {}
}

// MARK: - Notifications

extension Notification.Name {
    struct SecuredStore {
        /// Raised when store is purged
        static let securedStorePurged = Notification.Name("adamant.SecuredStore.purged")
        
        private init() {}
    }
}

extension StoreKey {
    enum notificationsService {
        static let notificationsMode = "notifications.mode"
        static let customBadgeNumber = "notifications.number"
        static let notificationsSound = "notifications.sound"
    }
    
    enum visibleWallets {
        static let invisibleWallets = "invisible.wallets"
        static let indexWallets = "index.wallets"
        static let indexWalletsWithInvisible = "index.wallets.include.ivisible"
        static let useCustomIndexes = "visible.wallets.useCustomIndexes"
        static let useCustomVisibility = "visible.wallets.useCustomVisibility"
    }
    
    enum increaseFee {
        static let increaseFee = "increaseFee"
    }
    
    enum crashlytic {
        static let crashlyticEnabled = "crashlyticEnabled"
    }
    
    enum emoji {
        static let visibleEmojiis = "visibleEmojiis"
    }
}

protocol SecuredStore: AnyObject {
    func get<T: Decodable>(_ key: String) -> T?
    func set<T: Encodable>(_ value: T, for key: String)

    func remove(_ key: String)
    
    /// Remove everything
    func purgeStore()
}
