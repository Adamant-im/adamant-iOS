//
//  AdamantIncreaseFeeService.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 14.03.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Combine
import CommonKit
import Foundation

final class AdamantIncreaseFeeService: IncreaseFeeService, @unchecked Sendable {

    // MARK: Dependencies

    let SecureStore: SecureStore

    // MARK: Proprieties

    @Atomic private var increaseFeeData: [String: Bool] = [:]
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

        NotificationCenter.default
            .notifications(named: .AdamantAccountService.userLoggedIn)
            .sink { [weak self] _ in
                self?.userLoggedIn()
            }
            .store(in: &notificationsSet)
    }

    // MARK: Notification actions

    private func userLoggedIn() {
        increaseFeeData = getIncreaseFeeDictionary()
    }

    private func userLoggedOut() {
        SecureStore.remove(StoreKey.increaseFee.increaseFee)
        increaseFeeData = [:]
    }

    // MARK: Check

    func isIncreaseFeeEnabled(for tokenUniqueID: String) -> Bool {
        return increaseFeeData[tokenUniqueID] ?? false
    }

    func setIncreaseFeeEnabled(for tokenUniqueID: String, value: Bool) {
        $increaseFeeData.mutate {
            $0[tokenUniqueID] = value
            SecureStore.set($0, for: StoreKey.increaseFee.increaseFee)
        }
    }

    private func getIncreaseFeeDictionary() -> [String: Bool] {
        guard let result: [String: Bool] = SecureStore.get(StoreKey.increaseFee.increaseFee) else {
            return [:]
        }

        return result
    }
}
