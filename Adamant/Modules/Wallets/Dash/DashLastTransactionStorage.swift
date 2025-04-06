//
//  DashLastTransactionStorage.swift
//  Adamant
//
//  Created by Christian Benua on 22.01.2025.
//  Copyright © 2025 Adamant. All rights reserved.
//

import CommonKit
import Foundation

final class DashLastTransactionStorage: DashLastTransactionStorageProtocol {

    private let SecureStore: SecureStore

    init(SecureStore: SecureStore) {
        self.SecureStore = SecureStore
    }

    func getLastTransactionId() -> String? {
        guard
            let hash: String = self.SecureStore.get(Constants.transactionIdKey),
            let timestampString: String = self.SecureStore.get(Constants.transactionTimeKey),
            let timestamp = Double(string: timestampString)
        else { return nil }

        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let timeAgo = -1 * date.timeIntervalSinceNow

        if timeAgo > Constants.tenMinutes {  // 10m waiting for transaction complete
            self.SecureStore.remove(Constants.transactionTimeKey)
            self.SecureStore.remove(Constants.transactionIdKey)
            return nil
        } else {
            return hash
        }
    }

    func setLastTransactionId(_ id: String?) {
        if let value = id {
            let timestamp = Date().timeIntervalSince1970
            self.SecureStore.set("\(timestamp)", for: Constants.transactionTimeKey)
            self.SecureStore.set(value, for: Constants.transactionIdKey)
        } else {
            self.SecureStore.remove(Constants.transactionTimeKey)
            self.SecureStore.remove(Constants.transactionIdKey)
        }
    }
}

private enum Constants {
    static let transactionTimeKey = "lastDashTransactionTime"
    static let transactionIdKey = "lastDashTransactionId"

    static let tenMinutes: TimeInterval = 10 * 60
}
