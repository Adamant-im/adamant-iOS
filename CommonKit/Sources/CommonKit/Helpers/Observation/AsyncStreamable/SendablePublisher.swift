//
//  SendablePublisher.swift
//  CommonKit
//
//  Created by Andrew G on 12.10.2024.
//

import Foundation
import Combine

public actor SendablePublisher<
    P: Publisher
>: StreamSendableActor where P.Output: Sendable, P.Failure: Sendable {
    public var streamSubscription: AnyCancellable?
    
    nonisolated public let streamSender: AsyncStreamSender<
        @Sendable (isolated SendablePublisher<P>) -> Void
    > = .init()
    
    private var subscriptions = [UUID: AnyCancellable]()
    
    public let publisher: P
    
    public init(_ publisher: @autoclosure @Sendable () -> P) {
        self.publisher = publisher()
        Task { await configureStream() }
    }
}

extension SendablePublisher: AsyncStreamable {
    public nonisolated func makeSequence() -> AsyncThrowingStream<P.Output, any Error> {
        .init { continuation in
            task { $0.subscribe(continuation) }
        }
    }
}

private extension SendablePublisher {
    func subscribe(_ continuation: AsyncThrowingStream<P.Output, any Error>.Continuation) {
        let id = UUID()
        
        subscriptions[id] = publisher.sink(
            receiveCompletion: { continuation.finish(throwing: $0.error) },
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

private extension Subscribers.Completion {
    var error: Failure? {
        switch self {
        case .finished:
            return nil
        case let .failure(error):
            return error
        }
    }
}
