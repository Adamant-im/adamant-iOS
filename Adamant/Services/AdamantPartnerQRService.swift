//
//  PartnerQRService.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 28.10.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Combine
import CommonKit
import Foundation

final class AdamantPartnerQRService: PartnerQRService, @unchecked Sendable {

    // MARK: Dependencies

    let SecureStore: SecureStore

    // MARK: Proprieties

    @Atomic private var notificationsSet: Set<AnyCancellable> = []

    // MARK: Lifecycle

    init(SecureStore: SecureStore) {
        self.SecureStore = SecureStore

        NotificationCenter.default
            .notifications(named: .AdamantAccountService.userLoggedOut)
            .sink { [weak self] _ in
                self?.userLoggedOut()
            }
            .store(in: &notificationsSet)
    }

    // MARK: Notification actions

    private func userLoggedOut() {
        setIncludeNameEnabled(true)
        setIncludeURLEnabled(true)
    }

    // MARK: Update data

    func setIncludeNameEnabled(_ value: Bool) {
        SecureStore.set(value, for: StoreKey.partnerQR.includeNameEnabled)
    }

    func isIncludeNameEnabled() -> Bool {
        guard
            let result: Bool = SecureStore.get(
                StoreKey.partnerQR.includeNameEnabled
            )
        else {
            return true
        }

        return result
    }

    func setIncludeURLEnabled(_ value: Bool) {
        SecureStore.set(value, for: StoreKey.partnerQR.includeURLEnabled)
    }

    func isIncludeURLEnabled() -> Bool {
        guard
            let result: Bool = SecureStore.get(
                StoreKey.partnerQR.includeURLEnabled
            )
        else {
            return true
        }

        return result
    }
}
