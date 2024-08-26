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
    case note
    case antic
    case cheers
    case chord
    case droplet
    case handoff
    case milestone
    case passage
    case portal
    case rattle
    case rebound
    case slide
    case welcome
    
    var tag: String {
        switch self {
        case .none: return "none"
        case .noteDefault: return "def"
        case .inputDefault: return "ct"
        case .proud: return "pr"
        case .relax: return "rl"
        case .success: return "sh"
        case .note: return "note"
        case .antic: return "antic"
        case .cheers: return "chrs"
        case .chord: return "chord"
        case .droplet: return "droplet"
        case .handoff: return "hnoff"
        case .milestone: return "mlst"
        case .passage: return "psg"
        case .portal: return "portal"
        case .rattle: return "rattle"
        case .rebound: return "rbnd"
        case .slide: return "slide"
        case .welcome: return "welcome"
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
        case .note: return "note.mp3"
        case .antic: return "antic.mp3"
        case .cheers: return "cheers.mp3"
        case .chord: return "chord.mp3"
        case .droplet: return "droplet.mp3"
        case .handoff: return "handoff.mp3"
        case .milestone: return "milestone.mp3"
        case .passage: return "passage.mp3"
        case .portal: return "portal.mp3"
        case .rattle: return "rattle.mp3"
        case .rebound: return "rebound.mp3"
        case .slide: return "slide.mp3"
        case .welcome: return "welcome.mp3"
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
        case .note: return "Note"
        case .antic: return "Antic"
        case .cheers: return "Cheers"
        case .chord: return "Chord"
        case .droplet: return "Droplet"
        case .handoff: return "Handoff"
        case .milestone: return "Milestone"
        case .passage: return "Passage"
        case .portal: return "Portal"
        case .rattle: return "Rattle"
        case .rebound: return "Rebound"
        case .slide: return "Slide"
        case .welcome: return "Welcome"
        }
    }
    
    init?(fileName: String) {
        switch fileName {
        case "notification.mp3": self = .inputDefault
        case "default.mp3": self = .noteDefault
        case "so-proud-notification.mp3": self = .proud
        case "relax-message-tone.mp3": self = .relax
        case "short-success.mp3": self = .success
        case "note.mp3": self = .note
        case "antic.mp3": self = .antic
        case "cheers.mp3": self = .cheers
        case "chord.mp3": self = .chord
        case "droplet.mp3": self = .droplet
        case "handoff.mp3": self = .handoff
        case "milestone.mp3": self = .milestone
        case "passage.mp3": self = .passage
        case "portal.mp3": self = .portal
        case "rattle.mp3": self = .rattle
        case "rebound.mp3": self = .rebound
        case "slide.mp3": self = .slide
        case "welcome.mp3": self = .welcome
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

@MainActor
protocol NotificationsService: AnyObject {
    var notificationsMode: NotificationsMode { get }
    var notificationsSound: NotificationSound { get }
    var notificationsReactionSound: NotificationSound { get }
    var inAppSound: Bool { get }
    var inAppVibrate: Bool { get }
    var inAppToasts: Bool { get }
    
    func setInAppSound(_ value: Bool)
    func setInAppVibrate(_ value: Bool)
    func setInAppToasts(_ value: Bool)
    
    func setNotificationSound(
        _ sound: NotificationSound,
        for target: NotificationTarget
    )
    func setNotificationsMode(_ mode: NotificationsMode, completion: ((NotificationsServiceResult) -> Void)?)
    
    func showNotification(title: String, body: String, type: AdamantNotificationType)
    
    func setBadge(number: Int?)
    
    func removeAllPendingNotificationRequests()
    func removeAllDeliveredNotifications()
    
    // MARK: Background batch notifications
    func startBackgroundBatchNotifications()
    func stopBackgroundBatchNotifications()
}
