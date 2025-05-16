//
//  UserDefaultsWrapper.swift
//  CommonKit
//
//  Created by Sergei Veretennikov on 22.03.2025.
//

import Foundation

@propertyWrapper
public struct UserDefaultsStorage<T> {
    //user group.adamant.adamant-messenger to share UserDefaults Data to NotificationService and another app targets
    private let defaults = UserDefaults(suiteName: "group.adamant.adamant-messenger") ?? UserDefaults.standard
    private let key: String

    public var wrappedValue: T? {
        get {
            defaults.object(forKey: key) as? T
        }
        set {
            if newValue == nil {
                defaults.removeObject(forKey: key)
            } else {
                defaults.set(newValue, forKey: key)
            }
        }
    }

    public init(_ key: UserDefaultsKey) {
        self.key = key.rawValue
    }
}
