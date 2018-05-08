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

extension NotificationsMode {
	func toRaw() -> String {
		return String(self.rawValue)
	}
	
	init?(string: String) {
		guard let int = Int(string: string), let mode = NotificationsMode(rawValue: int) else {
			return nil
		}
		
		self = mode
	}
}

class AdamantNotificationsService: NotificationsService {
	// MARK: Dependencies
	var securedStore: SecuredStore!
	
	
	// MARK: Properties
	private(set) var notificationsMode: NotificationsMode = .disabled
	private(set) var customBadgeNumber = 0
	
	private var isBackgroundSession = false
	private var backgroundNotifications = 0
	
	// MARK: Lifecycle
	init() {
		NotificationCenter.default.addObserver(forName: Notification.Name.AdamantAccountService.userLoggedIn, object: nil, queue: OperationQueue.main) { [weak self] _ in
			UNUserNotificationCenter.current().removeAllDeliveredNotifications()
			UIApplication.shared.applicationIconBadgeNumber = 0
			
			if let securedStore = self?.securedStore, let raw = securedStore.get(StoreKey.notificationsService.notificationsMode), let mode = NotificationsMode(string: raw) {
				self?.setNotificationsMode(mode, completion: nil)
			} else {
				self?.setNotificationsMode(.disabled, completion: nil)
			}
		}
		
		NotificationCenter.default.addObserver(forName: Notification.Name.AdamantAccountService.userLoggedOut, object: nil, queue: nil) { [weak self] _ in
			self?.setNotificationsMode(.disabled, completion: nil)
		}
	}
	
	deinit {
		NotificationCenter.default.removeObserver(self)
	}
}


// MARK: - Notifications mode {
extension AdamantNotificationsService {
	func setNotificationsMode(_ mode: NotificationsMode, completion: ((NotificationsServiceResult) -> Void)?) {
		switch mode {
		case .disabled:
			UIApplication.shared.unregisterForRemoteNotifications()
			UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalNever)
			securedStore.remove(StoreKey.notificationsService.notificationsMode)
			notificationsMode = mode
			NotificationCenter.default.post(name: Notification.Name.AdamantNotificationService.notificationsModeChanged, object: self)
			completion?(.success)
			return
			
		case .backgroundFetch:
			authorizeNotifications { [weak self] (success, error) in
				guard success else {
					completion?(.denied(error: error))
					return
				}
				
				UIApplication.shared.unregisterForRemoteNotifications()
				UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)
				self?.securedStore.set(mode.toRaw(), for: StoreKey.notificationsService.notificationsMode)
				self?.notificationsMode = mode
				NotificationCenter.default.post(name: Notification.Name.AdamantNotificationService.notificationsModeChanged, object: self)
				completion?(.success)
			}
			
		case .push:
			authorizeNotifications { [weak self] (success, error) in
				guard success else {
					completion?(.denied(error: error))
					return
				}
				
				UIApplication.shared.registerForRemoteNotifications()
				UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalNever)
				self?.securedStore.set(mode.toRaw(), for: StoreKey.notificationsService.notificationsMode)
				self?.notificationsMode = mode
				NotificationCenter.default.post(name: Notification.Name.AdamantNotificationService.notificationsModeChanged, object: self)
				completion?(.success)
			}
		}
	}
	
	private func authorizeNotifications(completion: @escaping (Bool, Error?) -> Void) {
		UNUserNotificationCenter.current().getNotificationSettings { settings in
			switch settings.authorizationStatus {
			case .authorized:
				completion(true, nil)
				
			case .denied:
				completion(false, nil)
				
			case .notDetermined:
				UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound], completionHandler: { (granted, error) in
					completion(granted, error)
				})
			}
		}
	}
}


// MARK: - Posting & removing Notifications
extension AdamantNotificationsService {
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


// MARK: - Background batch notifications
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
