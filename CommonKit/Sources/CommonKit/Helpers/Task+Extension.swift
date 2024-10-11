//
//  Task+Extension.swift
//  Adamant
//
//  Created by Andrey Golubenko on 06.02.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation
import Combine

public extension Task {
    func eraseToAnyCancellable() -> AnyCancellable {
        AnyCancellable(cancel)
    }
}

public extension Task where Success == Never, Failure == Never {
    static func sleep(interval: TimeInterval) async {
        try? await Task<Never, Never>.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
    }
    
    /// Avoid using it. It lowers performance due to changing threads.
    @discardableResult
    static func sync<T: Sendable>(_ action: @Sendable @escaping () async -> T) -> T {
        _sync(action)
    }
}

@discardableResult
private func _sync<T: Sendable>(_ action: @Sendable @escaping () async -> T) -> T {
    let result = Atomic<T?>(wrappedValue: nil)
    let semaphore = DispatchSemaphore(value: .zero)
    
    Task {
        result.value = await action()
        semaphore.signal()
    }
    
    semaphore.wait()
    return result.value!
}
