//
//  AdamantNotificationsService.swift
//  Adamant
//
//  Created by Anokhov Pavel on 09.03.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
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
							self?.showNotifications = true
							
						case .denied:
							self?.showNotifications = false
							
						case .notDetermined:
							self?.showNotifications = false
						}
					}
				} else {
					showNotifications = false
				}
			} else {
				showNotifications = false
			}
		}
	}
	
	
	// MARK: Properties
	private(set) var showNotifications: Bool = false
	
	
	// MARK: Notifications authorization
	func setNotificationsEnabled(_ enabled: Bool, completion: @escaping (NotificationsServiceResult) -> Void) {
		guard showNotifications != enabled else {
			return
		}
		
		if enabled { // MARK: Turn on
			UNUserNotificationCenter.current().getNotificationSettings(completionHandler: { [weak self] settings in
				switch settings.authorizationStatus {
				case .authorized:
					self?.showNotifications = true
					self?.securedStore.set(String(true), for: StoreKey.notificationsService.notificationsEnabled)
					NotificationCenter.default.post(name: Notification.Name.adamantShowNotificationsChanged, object: self)
					completion(.success)
					
				case .denied:
					self?.showNotifications = false
					completion(.denied(error: nil))
					
				case .notDetermined:
					UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound], completionHandler: { (granted, error) in
						self?.showNotifications = false
						if granted {
							completion(.success)
						} else {
							completion(.denied(error: error))
						}
					})
				}
			})
		} else { // MARK: Turn off
			showNotifications = false
			securedStore.remove(StoreKey.notificationsService.notificationsEnabled)
			NotificationCenter.default.post(name: Notification.Name.adamantShowNotificationsChanged, object: self)
		}
	}
	
	
	// MARK: Posting & removing Notifications
	func showNotification(title: String, body: String, type: AdamantNotificationType) {
		let content = UNMutableNotificationContent()
		content.title = title
		content.body = body
		
		let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
		let request = UNNotificationRequest(identifier: type.identifier, content: content, trigger: trigger)
		
		UNUserNotificationCenter.current().add(request) { error in
			if let error = error {
				print(error)
			}
		}
	}
	
	func removeAllPendingNotificationRequests(ofType type: AdamantNotificationType) {
		UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [type.identifier])
	}
}
