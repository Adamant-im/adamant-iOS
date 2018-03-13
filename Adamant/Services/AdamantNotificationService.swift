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
	private(set) var notificationsEnabled: Bool = false
	
	
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
		content.badge = type.badge
		
		let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
		let request = UNNotificationRequest(identifier: type.identifier, content: content, trigger: trigger)
		
		UNUserNotificationCenter.current().add(request) { error in
			if let error = error {
				print(error)
			}
		}
	}
	
	func removeAllPendingNotificationRequests() {
		UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
	}
	
	func removeAllDeliveredNotifications() {
		UNUserNotificationCenter.current().removeAllDeliveredNotifications()
		UIApplication.shared.applicationIconBadgeNumber = 0
	}
}
