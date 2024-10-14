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
        .init(cancel)
    }
    
    func store<C>(in collection: inout C) where C: RangeReplaceableCollection, C.Element == AnyCancellable {
        eraseToAnyCancellable().store(in: &collection)
    }

    func store(in set: inout Set<AnyCancellable>) {
        eraseToAnyCancellable().store(in: &set)
    }
}

public extension Task where Success == Never, Failure == Never {
    static func sleep(interval: TimeInterval) async {
        try? await Task<Never, Never>.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
    }
    
    /// Avoid using it. It lowers performance due to changing threads.
    @discardableResult
    static func sync<T: Sendable>(_ action: @Sendable @escaping () async throws -> T) rethrows -> T {
        try _sync(action)
    }
}

@discardableResult
private func _sync<T: Sendable>(_ action: @Sendable @escaping () async throws -> T) rethrows -> T {
    var result: T?
    let semaphore = DispatchSemaphore(value: .zero)
    
    Task {
        result = try await action()
        semaphore.signal()
    }
    
    semaphore.wait()
    return result!
}
