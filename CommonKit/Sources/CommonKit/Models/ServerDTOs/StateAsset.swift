//
//  StateAsset.swift
//  Adamant
//
//  Created by Anokhov Pavel on 25.05.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

public struct StateAsset: Codable, Hashable, Sendable {
    public let key: String
    public let value: String
    public let type: StateType
    
    public init(key: String, value: String, type: StateType) {
        self.key = key
        self.value = value
        self.type = type
    }
}

/* JSON
"state": {
    "value": "myValue",
    "key": "myKey",
    "type": 0
}
*/
