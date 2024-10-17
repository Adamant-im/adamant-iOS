//
//  Actor+Extension.swift
//  CommonKit
//
//  Created by Andrew G on 13.10.2024.
//

public extension Actor {
    @discardableResult
    func isolated<T: Sendable>(
        _ closure: @escaping @Sendable (isolated Self) async throws -> T
    ) async rethrows -> T {
        try await closure(self)
    }
}
