//
//  AdamantCrashlyticsService.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 09.06.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation
import Combine
import Firebase
import CommonKit

@MainActor
final class AdamantCrashlyticsService: CrashlyticsService {
    
    // MARK: Dependencies
    
    let securedStore: SecuredStore
    
    // MARK: Proprieties
    
    @Atomic private var notificationsSet: Set<AnyCancellable> = []
    private var isConfigured = false
    
    // MARK: Lifecycle
    
    init(securedStore: SecuredStore) {
        self.securedStore = securedStore
        
        NotificationCenter.default
            .notifications(named: .AdamantAccountService.userLoggedOut)
            .sink { [weak self] _ in
                await self?.userLoggedOut()
            }
            .store(in: &notificationsSet)
    }
    
    // MARK: Notification actions
    
    private func userLoggedOut() {
        securedStore.remove(StoreKey.increaseFee.increaseFee)
        updateCrashlyticSDK(isEnabled: false)
    }
    
    // MARK: Update data
    
    func setCrashlyticsEnabled(_ value: Bool) {
        securedStore.set(value, for: StoreKey.crashlytic.crashlyticEnabled)
        updateCrashlyticSDK(isEnabled: value)
    }
    
    func isCrashlyticsEnabled() -> Bool {
        guard let result: Bool = securedStore.get(
            StoreKey.crashlytic.crashlyticEnabled
        ) else {
            return false
        }
        
        return result
    }
    
    func configureIfNeeded() {
        guard !isConfigured && isCrashlyticsEnabled() else { return }
        
        FirebaseApp.configure()
        isConfigured = true
    }
    
    private func updateCrashlyticSDK(isEnabled: Bool) {
        configureIfNeeded()
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(isEnabled)
    }
}
