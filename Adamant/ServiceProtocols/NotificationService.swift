//
//  NotificationService.swift
//  Adamant
//
//  Created by Anokhov Pavel on 09.03.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

extension StoreKey {
	struct notificationService {
		static let showNotifications = "notifications.show"
		
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
enum NotificationServiceResult {
	case success
	case denied(error: Error?)
}

protocol NotificationService {
	var showNotifications: Bool { get }
	
	func setShowNotifications(_ value: Bool, completion: @escaping (NotificationServiceResult) -> Void)
	
	func showNotification(title: String, body: String, type: AdamantNotificationType)
	func removeAllPendingNotificationRequests(ofType type: AdamantNotificationType)
}
