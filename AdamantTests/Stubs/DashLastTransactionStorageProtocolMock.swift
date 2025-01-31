//
//  DashLastTransactionStorageProtocolMock.swift
//  Adamant
//
//  Created by Christian Benua on 22.01.2025.
//  Copyright © 2025 Adamant. All rights reserved.
//

@testable import Adamant
import CommonKit

final class DashLastTransactionStorageProtocolMock: DashLastTransactionStorageProtocol {
    
    var stubbedLastTransactionId: String?

    func getLastTransactionId() -> String? {
        return stubbedLastTransactionId
    }
    
    var invokedSetLastTransactionId: Bool = false
    var invokedSetLastTransactionIdCount: Int = 0
    var invokedSetLastTransactionIdParameters: String?
    
    func setLastTransactionId(_ id: String?) {
        invokedSetLastTransactionId = true
        invokedSetLastTransactionIdCount += 1
        invokedSetLastTransactionIdParameters = id
    }
}
