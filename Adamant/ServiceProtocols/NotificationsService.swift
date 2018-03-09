//
//  NotificationsService.swift
//  Adamant
//
//  Created by Anokhov Pavel on 09.03.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

extension String.adamantLocalized {
	struct notificationsService {
		static let notificationsDisabled = NSLocalizedString("Notifications disabled. You can reenable notifications in Settings", comment: "Notifications: User has disabled notifications. Head him into settings.")
		
		private init() {}
	}
}

extension StoreKey {
	struct notificationsService {
		static let notificationsEnabled = "notifications.show"
		
		private init() {}
	}
}

/// Supported notification types
///
/// - message: text message
/// - transaction: token transaction
/// - custom: other
enum AdamantNotificationType {
	case message
	case transaction
	case custom(identifier: String)
	
	var identifier: String {
		switch self {
		case .message:
			return "message"
			
		case .transaction:
			return "transaction"
			
		case .custom(let identifier):
			return identifier
		}
	}
}

// MARK: - Notifications
extension Notification.Name {
	/// Raised when user has logged out.
	static let adamantShowNotificationsChanged = Notification.Name("adamantShowNotifications")
}


// MARK: - Protocol
enum NotificationsServiceResult {
	case success
	case denied(error: Error?)
}

protocol NotificationsService {
	var showNotifications: Bool { get }
	
	func setNotificationsEnabled(_ enabled: Bool, completion: @escaping (NotificationsServiceResult) -> Void)
	
	func showNotification(title: String, body: String, type: AdamantNotificationType)
	func removeAllPendingNotificationRequests(ofType type: AdamantNotificationType)
}
