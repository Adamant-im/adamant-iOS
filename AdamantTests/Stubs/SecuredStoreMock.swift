//
//  SecuredStoreMock.swift
//  Adamant
//
//  Created by Christian Benua on 28.01.2025.
//  Copyright © 2025 Adamant. All rights reserved.
//

import CommonKit

final class SecuredStoreMock: SecuredStore {
    var invokedGet: Bool = false
    var invokedGetCount: Int = 0
    var invokedGetParameters: String?
    var stubbedGetResult: Any?
    
    func get<T: Decodable>(_ key: String) -> T? {
        invokedGet = true
        invokedGetCount += 1
        invokedGetParameters = key
        return stubbedGetResult as? T
    }
    
    var invokedSet: Bool = false
    var invokedSetCount: Int = 0
    var invokedSetParameters: (value: Any?, key: String)?
    
    func set<T: Encodable>(_ value: T, for key: String) {
        invokedSet = true
        invokedSetCount += 1
        invokedSetParameters = (value, key)
    }
    
    var invokedRemove: Bool = false
    var invokedRemoveCount: Int = 0
    var invokedRemoveParameters: String?
    
    func remove(_ key: String) {
        invokedRemove = true
        invokedRemoveCount += 1
        invokedRemoveParameters = key
    }
}
