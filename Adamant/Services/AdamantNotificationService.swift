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
import CommonKit
import Combine

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

@MainActor
final class AdamantNotificationsService: NotificationsService {
    // MARK: Dependencies
    private let securedStore: SecuredStore
    weak var accountService: AccountService?
    
    // MARK: Properties
    private(set) var notificationsMode: NotificationsMode = .disabled
    private(set) var customBadgeNumber = 0
    private(set) var notificationsSound: NotificationSound = .inputDefault
    private var isBackgroundSession = false
    private var backgroundNotifications = 0
    private var subscriptions = Set<AnyCancellable>()
    
    private var preservedBadgeNumber: Int?
    
    // MARK: Lifecycle
    nonisolated init(securedStore: SecuredStore) {
        self.securedStore = securedStore
        
        Task { @MainActor in
            NotificationCenter.default
                .publisher(for: .AdamantAccountService.userLoggedIn, object: nil)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in self?.onUserLoggedIn() }
                .store(in: &subscriptions)
            
            NotificationCenter.default
                .publisher(for: .AdamantAccountService.userLoggedOut, object: nil)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in self?.onUserLoggedOut() }
                .store(in: &subscriptions)
            
            NotificationCenter.default
                .publisher(for: .AdamantAccountService.stayInChanged, object: nil)
                .receive(on: DispatchQueue.main)
                .compactMap { $0.userInfo?[AdamantUserInfoKey.AccountService.newStayInState] as? Bool }
                .sink { [weak self] in self?.onStayInChanged($0) }
                .store(in: &subscriptions)
        }
    }
    
    private func onUserLoggedIn() {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        UIApplication.shared.applicationIconBadgeNumber = 0
        
        if let raw: String = securedStore.get(StoreKey.notificationsService.notificationsMode),
            let mode = NotificationsMode(string: raw) {
            setNotificationsMode(mode, completion: nil)
        } else {
            setNotificationsMode(.disabled, completion: nil)
        }
        
        if let raw: String = securedStore.get(StoreKey.notificationsService.notificationsSound),
            let sound = NotificationSound(fileName: raw) {
            setNotificationSound(sound)
        } else {
            setNotificationsMode(.disabled, completion: nil)
        }
        
        preservedBadgeNumber = nil
    }
    
    private func onUserLoggedOut() {
        setNotificationsMode(.disabled, completion: nil)
        setNotificationSound(.inputDefault)
        securedStore.remove(StoreKey.notificationsService.notificationsMode)
        securedStore.remove(StoreKey.notificationsService.notificationsSound)
        preservedBadgeNumber = nil
    }
    
    private func onStayInChanged(_ stayIn: Bool) {
        if stayIn {
            setBadge(number: preservedBadgeNumber, force: false)
        } else {
            preservedBadgeNumber = nil
            setBadge(number: nil, force: true)
        }
    }
}

// MARK: - Notifications Sound {
extension AdamantNotificationsService {
    func setNotificationSound(_ sound: NotificationSound) {
        notificationsSound = sound
        securedStore.set(sound.fileName, for: StoreKey.notificationsService.notificationsSound)
        NotificationCenter.default.post(name: Notification.Name.AdamantNotificationService.notificationsSoundChanged,
                                        object: self,
                                        userInfo: nil)
    }
}

// MARK: - Notifications mode {
extension AdamantNotificationsService {
    func setNotificationsMode(_ mode: NotificationsMode, completion: ((NotificationsServiceResult) -> Void)?) {
        switch mode {
        case .disabled:
            AdamantNotificationsService.configureUIApplicationFor(mode: mode)
            securedStore.remove(StoreKey.notificationsService.notificationsMode)
            notificationsMode = mode
            
            NotificationCenter.default.post(name: Notification.Name.AdamantNotificationService.notificationsModeChanged,
                                            object: self,
                                            userInfo: [AdamantUserInfoKey.NotificationsService.newNotificationsMode: mode])
            
            completion?(.success)
            return
            
        case .push:
            guard let account = accountService?.account, account.balance > AdamantApiService.KvsFee else {
                completion?(.failure(error: .notEnoughMoney))
                return
            }
            
            fallthrough
            
        case .backgroundFetch:
            guard accountService?.hasStayInAccount ?? false else {
                completion?(.failure(error: .notStayedLoggedIn))
                return
            }
            
            authorizeNotifications { [weak self] (success, error) in
                guard success else {
                    completion?(.failure(error: .denied(error: error)))
                    return
                }
                
                Task { @MainActor in
                    AdamantNotificationsService.configureUIApplicationFor(mode: mode)
                }
                
                self?.securedStore.set(
                    mode.toRaw(),
                    for: StoreKey.notificationsService.notificationsMode
                )
                
                self?.notificationsMode = mode
                
                NotificationCenter.default.post(
                    name: .AdamantNotificationService.notificationsModeChanged,
                    object: self,
                    userInfo: [AdamantUserInfoKey.NotificationsService.newNotificationsMode: mode]
                )
                
                completion?(.success)
            }
        }
    }
    
    private func authorizeNotifications(completion: @escaping (Bool, Error?) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized, .ephemeral:
                completion(true, nil)
                
            case .denied, .provisional:
                completion(false, nil)
                
            case .notDetermined:
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound], completionHandler: { (granted, error) in
                    completion(granted, error)
                })
            @unknown default:
                completion(false, nil)
            }
        }
    }
    
    private static func configureUIApplicationFor(mode: NotificationsMode) {
        switch mode {
        case .disabled:
            UIApplication.shared.unregisterForRemoteNotifications()
            UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalNever)
            
        case .backgroundFetch:
            UIApplication.shared.unregisterForRemoteNotifications()
            UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
            
        case .push:
            UIApplication.shared.registerForRemoteNotifications()
            UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalNever)
        }
    }
}

// MARK: - Posting & removing Notifications
extension AdamantNotificationsService {
    func showNotification(title: String, body: String, type: AdamantNotificationType) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body

        if notificationsSound == .none {
            content.sound = nil
        } else {
            content.sound = UNNotificationSound(named: UNNotificationSoundName(notificationsSound.fileName))
        }

        if let number = type.badge {
            DispatchQueue.onMainSync {
                content.badge = NSNumber(value: UIApplication.shared.applicationIconBadgeNumber + backgroundNotifications + number)
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
        setBadge(number: number, force: false)
    }
    
    private func setBadge(number: Int?, force: Bool) {
        if !force {
            guard let stayIn = accountService?.hasStayInAccount, stayIn else {
                preservedBadgeNumber = number
                return
            }
        }
        
        let appIconBadgeNumber: Int
        
        if let number = number {
            customBadgeNumber = number
            appIconBadgeNumber = number
            securedStore.set(String(number), for: StoreKey.notificationsService.customBadgeNumber)
        } else {
            customBadgeNumber = 0
            appIconBadgeNumber = 0
            securedStore.remove(StoreKey.notificationsService.customBadgeNumber)
        }
        
        DispatchQueue.onMainAsync {
            UIApplication.shared.applicationIconBadgeNumber = appIconBadgeNumber
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
