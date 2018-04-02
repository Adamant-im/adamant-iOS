//
//  AdamantNotificationsService.swift
//  Adamant
//
//  Created by Anokhov Pavel on 09.03.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import UIKit
import UserNotifications

class AdamantNotificationsService: NotificationsService {
	// MARK: Dependencies
	var securedStore: SecuredStore! {
		didSet {
			if let raw = securedStore.get(StoreKey.notificationsService.notificationsEnabled), let show = Bool(raw) {
				if show {
					UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
						switch settings.authorizationStatus {
						case .authorized:
							self?.notificationsEnabled = true
							
						case .denied:
							self?.notificationsEnabled = false
							
						case .notDetermined:
							self?.notificationsEnabled = false
						}
					}
				} else {
					notificationsEnabled = false
				}
			} else {
				notificationsEnabled = false
			}
		}
	}
	
	
	// MARK: Properties
	private(set) var notificationsEnabled = false
	private(set) var customBadgeNumber = 0
	
	private var isBackgroundSession = false
	private var backgroundNotifications = 0
	
	// MARK: Lifecycle
	init() {
		NotificationCenter.default.addObserver(forName: Notification.Name.adamantUserLoggedIn, object: nil, queue: OperationQueue.main) { _ in
			UNUserNotificationCenter.current().removeAllDeliveredNotifications()
			UIApplication.shared.applicationIconBadgeNumber = 0
		}
		
		NotificationCenter.default.addObserver(forName: Notification.Name.adamantUserLoggedOut, object: nil, queue: nil) { [weak self] _ in
			self?.notificationsEnabled = false
			self?.securedStore.remove(StoreKey.notificationsService.notificationsEnabled)
			NotificationCenter.default.post(name: Notification.Name.adamantShowNotificationsChanged, object: self)
		}
	}
	
	deinit {
		NotificationCenter.default.removeObserver(self)
	}
	
	
	// MARK: Notifications authorization
	func setNotificationsEnabled(_ enabled: Bool, completion: @escaping (NotificationsServiceResult) -> Void) {
		guard notificationsEnabled != enabled else {
			return
		}
		
		if enabled { // MARK: Turn on
			UNUserNotificationCenter.current().getNotificationSettings(completionHandler: { [weak self] settings in
				switch settings.authorizationStatus {
				case .authorized:
					self?.notificationsEnabled = true
					self?.securedStore.set(String(true), for: StoreKey.notificationsService.notificationsEnabled)
					NotificationCenter.default.post(name: Notification.Name.adamantShowNotificationsChanged, object: self)
					completion(.success)
					
				case .denied:
					self?.notificationsEnabled = false
					completion(.denied(error: nil))
					
				case .notDetermined:
					UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound], completionHandler: { (granted, error) in
						self?.notificationsEnabled = false
						if granted {
							completion(.success)
						} else {
							completion(.denied(error: error))
						}
					})
				}
			})
		} else { // MARK: Turn off
			notificationsEnabled = false
			securedStore.remove(StoreKey.notificationsService.notificationsEnabled)
			NotificationCenter.default.post(name: Notification.Name.adamantShowNotificationsChanged, object: self)
		}
	}
	
	
	// MARK: Posting & removing Notifications
	func showNotification(title: String, body: String, type: AdamantNotificationType) {
		let content = UNMutableNotificationContent()
		content.title = title
		content.body = body
		content.sound = UNNotificationSound(named: "notification.mp3")
		
		if let number = type.badge {
			if Thread.isMainThread {
				content.badge = NSNumber(value: UIApplication.shared.applicationIconBadgeNumber + backgroundNotifications + number)
			} else {
				DispatchQueue.main.sync {
					content.badge = NSNumber(value: UIApplication.shared.applicationIconBadgeNumber + backgroundNotifications + number)
				}
			}
			
			if isBackgroundSession {
				backgroundNotifications += number
			}
		}
		
		let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
		let request = UNNotificationRequest(identifier: type.identifier, content: content, trigger: trigger)
		
		UNUserNotificationCenter.current().add(request) { error in
			if let error = error {
				print(error)
			}
		}
	}
	
	func setBadge(number: Int?) {
		if let number = number {
			customBadgeNumber = number
			UIApplication.shared.applicationIconBadgeNumber = number
			securedStore.set(String(number), for: StoreKey.notificationsService.customBadgeNumber)
		} else {
			customBadgeNumber = 0
			UIApplication.shared.applicationIconBadgeNumber = 0
			securedStore.remove(StoreKey.notificationsService.customBadgeNumber)
		}
	}
	
	func removeAllPendingNotificationRequests() {
		UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
		UIApplication.shared.applicationIconBadgeNumber = customBadgeNumber
	}
	
	func removeAllDeliveredNotifications() {
		UNUserNotificationCenter.current().removeAllDeliveredNotifications()
		UIApplication.shared.applicationIconBadgeNumber = customBadgeNumber
	}
}

// MARK: Background batch notifications
extension AdamantNotificationsService {
	func startBackgroundBatchNotifications() {
		isBackgroundSession = true
		backgroundNotifications = 0
	}
	
	func stopBackgroundBatchNotifications() {
		isBackgroundSession = false
		backgroundNotifications = 0
	}
}
