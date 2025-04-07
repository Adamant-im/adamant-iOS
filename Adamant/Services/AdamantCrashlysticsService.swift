//
//  AdamantCrashlyticsService.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 09.06.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Combine
import CommonKit
import Firebase
import Foundation

@MainActor
final class AdamantCrashlyticsService: CrashlyticsService {

    // MARK: Dependencies

    let SecureStore: SecureStore

    // MARK: Proprieties

    @Atomic private var notificationsSet: Set<AnyCancellable> = []
    private var isConfigured = false

    // MARK: Lifecycle

    init(SecureStore: SecureStore) {
        self.SecureStore = SecureStore

        NotificationCenter.default
            .notifications(named: .AdamantAccountService.userLoggedOut)
            .sink { [weak self] _ in
                await self?.userLoggedOut()
            }
            .store(in: &notificationsSet)
    }

    // MARK: Notification actions

    private func userLoggedOut() {
        SecureStore.remove(StoreKey.increaseFee.increaseFee)
        updateCrashlyticSDK(isEnabled: false)
    }

    // MARK: Update data

    func setCrashlyticsEnabled(_ value: Bool) {
        SecureStore.set(value, for: StoreKey.crashlytic.crashlyticEnabled)
        updateCrashlyticSDK(isEnabled: value)
    }

    func isCrashlyticsEnabled() -> Bool {
        guard
            let result: Bool = SecureStore.get(
                StoreKey.crashlytic.crashlyticEnabled
            )
        else {
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
