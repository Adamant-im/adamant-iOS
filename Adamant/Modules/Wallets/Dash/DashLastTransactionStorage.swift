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
    
    private let securedStore: SecuredStore
    
    init(securedStore: SecuredStore) {
        self.securedStore = securedStore
    }
    
    func getLastTransactionId() -> String? {
        guard
            let hash: String = self.securedStore.get(Constants.transactionIdKey),
            let timestampString: String = self.securedStore.get(Constants.transactionTimeKey),
            let timestamp = Double(string: timestampString)
        else { return nil }
        
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let timeAgo = -1 * date.timeIntervalSinceNow
        
        if timeAgo > Constants.tenMinutes { // 10m waiting for transaction complete
            self.securedStore.remove(Constants.transactionTimeKey)
            self.securedStore.remove(Constants.transactionIdKey)
            return nil
        } else {
            return hash
        }
    }
    
    func setLastTransactionId(_ id: String?) {
        if let value = id {
            let timestamp = Date().timeIntervalSince1970
            self.securedStore.set("\(timestamp)", for: Constants.transactionTimeKey)
            self.securedStore.set(value, for: Constants.transactionIdKey)
        } else {
            self.securedStore.remove(Constants.transactionTimeKey)
            self.securedStore.remove(Constants.transactionIdKey)
        }
    }
}

private enum Constants {
    static let transactionTimeKey = "lastDashTransactionTime"
    static let transactionIdKey = "lastDashTransactionId"
    
    static let tenMinutes: TimeInterval = 10 * 60
}
