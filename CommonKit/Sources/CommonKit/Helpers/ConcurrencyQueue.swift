//
//  ConcurrencyQueue.swift
//
//
//  Created by Andrew G on 24.08.2024.
//

import Foundation

public actor ConcurrencyQueue {
    private var isPerforming = false
    private var actions = [@Sendable () async -> Void]()
    
    public func add(_ action: @Sendable @escaping () async -> Void) {
        actions.append(action)
        guard !isPerforming else { return }
        isPerforming = true
        Task { await perform() }
    }
    
    public init() {}
}

public extension ConcurrencyQueue {
    nonisolated func syncAdd(_ action: @Sendable @escaping () async -> Void) {
        let semaphore = DispatchSemaphore(value: .zero)
        
        Task {
            await add(action)
            semaphore.signal()
        }
        
        semaphore.wait()
    }
}

private extension ConcurrencyQueue {
    func perform() async {
        while !actions.isEmpty {
            // Now it's O(n). It's possible to achieve O(1). But we will not do it.
            // "Premature optimization is the root of all evil." ~ Donald Knuth
            await actions.removeFirst()()
        }
        
        isPerforming = false
    }
}
