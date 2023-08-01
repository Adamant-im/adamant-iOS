//
//  NotificationsService.swift
//  Adamant
//
//  Created by Anokhov Pavel on 09.03.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import CommonKit

enum NotificationsMode: Int {
    case disabled
    case backgroundFetch
    case push
    
    var localized: String {
        switch self {
        case .disabled:
            return .localized("Notifications.Mode.NotificationsDisabled", comment: "Notifications: Disable notifications")
            
        case .backgroundFetch:
            return .localized("Notifications.Mode.BackgroundFetch", comment: "Notifications: Use Background fetch notifications")
            
        case .push:
            return .localized("Notifications.Mode.ApplePush", comment: "Notifications: Use Apple Push notifications")
        }
    }
}

enum NotificationSound: String {
    case none
    case noteDefault
    case inputDefault
    case proud
    case relax
    case success
    
    var tag: String {
        switch self {
        case .none: return "none"
        case .noteDefault: return "def"
        case .inputDefault: return "ct"
        case .proud: return "pr"
        case .relax: return "rl"
        case .success: return "sh"
        }
    }
    
    var fileName: String {
        switch self {
        case .none: return ""
        case .noteDefault: return "default.mp3"
        case .inputDefault: return "notification.mp3"
        case .proud: return "so-proud-notification.mp3"
        case .relax: return "relax-message-tone.mp3"
        case .success: return "short-success.mp3"
        }
    }
    
    var localized: String {
        switch self {
        case .none: return "None"
        case .noteDefault: return "Tri-tone (iOS Default)"
        case .inputDefault: return "Input"
        case .proud: return "Proud"
        case .relax: return "Relax"
        case .success: return "Success"
        }
    }
    
    init?(fileName: String) {
        switch fileName {
        case "notification.mp3": self = .inputDefault
        case "default.mp3": self = .noteDefault
        case "so-proud-notification.mp3": self = .proud
        case "relax-message-tone.mp3": self = .relax
        case "short-success.mp3": self = .success
        case "": self = .none
        default: self = .inputDefault
        }
    }
}

/// Supported notification types
///
/// - message: text message
/// - transaction: token transaction
/// - custom: other
enum AdamantNotificationType {
    case newMessages(count: Int)
    case newTransactions(count: Int)
    case custom(identifier: String, badge: Int?)
    
    var identifier: String {
        switch self {
        case .newMessages:
            return "newMessages"
            
        case .newTransactions:
            return "newTransactions"
            
        case .custom(let identifier, _):
            return identifier
        }
    }
    
    var badge: Int? {
        switch self {
        case .newMessages(let count):
            return count
            
        case .newTransactions(let count):
            return count
            
        case .custom(_, let badge):
            return badge
        }
    }
}

// MARK: - Notifications
extension Notification.Name {
    struct AdamantNotificationService {
        /// Raised when user has logged out.
        static let notificationsModeChanged = Notification.Name("adamant.notificationService.notificationsMode")
        static let notificationsSoundChanged = Notification.Name("adamant.notificationService.notificationsSound")
        private init() {}
    }
}

extension AdamantUserInfoKey {
    struct NotificationsService {
        static let newNotificationsMode = "adamant.notificationsService.notificationsMode"
        
        private init() {}
    }
}

// MARK: - Protocol
enum NotificationsServiceResult {
    case success
    case failure(error: NotificationsServiceError)
}

enum NotificationsServiceError: Error {
    case notEnoughMoney
    case denied(error: Error?)
    case notStayedLoggedIn
}

extension NotificationsServiceError: RichError {
    var message: String {
        switch self {
        case .notEnoughMoney: return String.adamant.sharedErrors.notEnoughMoney
        case .denied: return NotificationStrings.notificationsDisabled
        case .notStayedLoggedIn: return NotificationStrings.notStayedLoggedIn
        }
    }
    
    var internalError: Error? {
        switch self {
        case .notEnoughMoney, .notStayedLoggedIn: return nil
        case .denied(let error): return error
        }
    }
    
    var level: ErrorLevel {
        switch self {
        case .notEnoughMoney, .notStayedLoggedIn: return .warning
        case .denied: return .error
        }
    }
}

protocol NotificationsService: AnyObject {
    var notificationsMode: NotificationsMode { get }
    var notificationsSound: NotificationSound { get }
    
    func setNotificationSound(_ sound: NotificationSound)
    func setNotificationsMode(_ mode: NotificationsMode, completion: ((NotificationsServiceResult) -> Void)?)
    
    func showNotification(title: String, body: String, type: AdamantNotificationType)
    
    func setBadge(number: Int?)
    
    func removeAllPendingNotificationRequests()
    func removeAllDeliveredNotifications()
    
    // MARK: Background batch notifications
    func startBackgroundBatchNotifications()
    func stopBackgroundBatchNotifications()
}
