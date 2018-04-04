//
//  NotificationsService.swift
//  Adamant
//
//  Created by Anokhov Pavel on 09.03.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

extension String.adamantLocalized {
	struct notifications {
		static let notificationsDisabled = NSLocalizedString("NotificationsService.NotificationsDisabled", comment: "Notifications: User has disabled notifications. Head him into settings")
		
		static let newMessageTitle = NSLocalizedString("NotificationsService.NewMessage.Title", comment: "Notifications: New message notification title")
		static let newMessageBody = NSLocalizedString("NotificationsService.NewMessage.BodyFormat", comment: "Notifications: new messages notification body. Using %d for amount")
		
		static let newTransferTitle = NSLocalizedString("NotificationsService.NewTransfer.Title", comment: "Notifications: New transfer transaction title")
		static let newTransferBody = NSLocalizedString("NotificationsService.NewTransfer.BodyFormat", comment: "Notifications: New transfer notification body. Using %d for amount")
		
		private init() {}
	}
}

extension StoreKey {
	struct notificationsService {
		static let notificationsEnabled = "notifications.show"
		static let customBadgeNumber = "notifications.number"
		
		private init() {}
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
		static let showNotificationsChanged = Notification.Name("adamant.notificationService.showNotifications")
		
		private init() {}
	}
}


// MARK: - Protocol
enum NotificationsServiceResult {
	case success
	case denied(error: Error?)
}

protocol NotificationsService: class {
	var notificationsEnabled: Bool { get }
	
	func setNotificationsEnabled(_ enabled: Bool, completion: @escaping (NotificationsServiceResult) -> Void)
	
	func showNotification(title: String, body: String, type: AdamantNotificationType)
	
	func setBadge(number: Int?)
	
	func removeAllPendingNotificationRequests()
	func removeAllDeliveredNotifications()
	
	// MARK: Background batch notifications
	func startBackgroundBatchNotifications()
	func stopBackgroundBatchNotifications()
}
