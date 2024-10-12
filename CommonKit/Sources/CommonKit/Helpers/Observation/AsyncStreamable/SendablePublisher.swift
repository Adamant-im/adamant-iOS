//
//  SendablePublisher.swift
//  CommonKit
//
//  Created by Andrew G on 12.10.2024.
//

import Foundation
import Combine

public actor SendablePublisher<P: Publisher> where P.Output: Sendable, P.Failure == Never {
    private var subscriptions = [UUID: AnyCancellable]()
    
    public let publisher: P
    
    public init(_ publisher: @autoclosure @Sendable () -> P) {
        self.publisher = publisher()
    }
}

extension SendablePublisher: AsyncStreamable {
    public nonisolated func makeSequence() -> AsyncStream<P.Output> {
        .init { continuation in
            Task { await subscribe(continuation) }
        }
    }
}

private extension SendablePublisher {
    func subscribe(_ continuation: AsyncStream<P.Output>.Continuation) {
        let id = UUID()
        
        subscriptions[id] = publisher.sink(
            receiveCompletion: { _ in continuation.finish() },
            receiveValue: { continuation.yield($0) }
        )
        
        continuation.onTermination = { [self] _ in
            Task { await removeSubscription(id: id) }
        }
    }
    
    func removeSubscription(id: UUID) {
        subscriptions.removeValue(forKey: id)
    }
}
