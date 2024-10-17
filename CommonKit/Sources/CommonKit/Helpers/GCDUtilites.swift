//
//  GCDUtilites.swift
//  Adamant
//
//  Created by Андрей on 29.04.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import Foundation

public extension DispatchQueue {
    @discardableResult
    static func onMainThreadSyncSafe<T: Sendable>(_ action: @MainActor () -> T) -> T {
        Thread.isMainThread
            ? MainActor.assumeIsolated(action)
            : DispatchQueue.main.sync(execute: action)
    }
    
    /// Do not use it anymore. It makes unclear in which order code is executed.
    static func onMainAsync(_ action: @escaping @MainActor () -> Void) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async(execute: action)
            return
        }
        
        MainActor.assumeIsolated(action)
    }
}
