//
//  DisposalBag.swift
//  CommonKit
//
//  Created by Andrew G on 12.10.2024.
//

import Combine

public struct DisposalBag {
    private var subscriptions = Set<AnyCancellable>()
    
    public mutating func add(_ subscription: AnyCancellable) {
        subscription.store(in: &subscriptions)
    }
}

public extension DisposalBag {
    mutating func task(_ action: @escaping @Sendable () async throws -> Void) {
        Task { try await action() }
            .eraseToAnyCancellable()
            .store(in: &self)
    }
}

public extension AnyCancellable {
    func store(in disposalBag: inout DisposalBag) {
        disposalBag.add(self)
    }
}
