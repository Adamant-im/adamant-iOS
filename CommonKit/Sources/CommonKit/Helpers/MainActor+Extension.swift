//
//  MainActor+Extension.swift
//  CommonKit
//
//  Created by Andrew G on 09.10.2024.
//

import Foundation

extension MainActor {
    @discardableResult
    public static func assumeIsolatedSafe<T: Sendable>(_ action: @MainActor () -> T) -> T {
        assertIsolated()
        return DispatchQueue.onMainThreadSyncSafe(action)
    }
}
