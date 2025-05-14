//
//  UserDefaultsManager.swift
//  CommonKit
//
//  Created by Владимир Клевцов on 2. 5. 2025..
//
public struct UserDefaultsManager {
    @UserDefaultsStorage(.needsToShowNoActiveNodesAlert)
    static var needsToShowNoActiveNodesAlert: Bool?

    @UserDefaultsStorage(.lastReceivedId)
    public static var lastReceivedId: [String]?

    public static func setInitialUserDefaults() {
        needsToShowNoActiveNodesAlert = true
    }
}

public extension UserDefaultsManager {
    static func addLastReceivedId(_ id: String) {
        var ids = lastReceivedId ?? []
        ids.removeAll { $0 == id }
        ids.insert(id, at: 0)
        if ids.count > 100 {
            ids = Array(ids.prefix(100))
        }
        lastReceivedId = ids
    }
}
