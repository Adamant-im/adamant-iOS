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
    struct notificationsService {
        static let notificationsMode = "notifications.mode"
        static let customBadgeNumber = "notifications.number"
        static let notificationsSound = "notifications.sound"
        
        private init() {}
    }
}

protocol SecuredStore: AnyObject {
    func get(_ key: String) -> String?
    func getArray(_ key: String) -> [String]?
    func set(_ value: String, for key: String)
    func set(_ value: [String], for key: String)
    func remove(_ key: String)
    
    /// Remove everything
    func purgeStore()
}
