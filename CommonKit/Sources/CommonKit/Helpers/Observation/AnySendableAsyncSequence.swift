//
//  AnySendableAsyncSequence.swift
//  CommonKit
//
//  Created by Andrew G on 13.10.2024.
//

@available(iOS, deprecated: 18, message: "`AsyncSequence.Failure` is available, so use the `any` keyword")
@available(macOS, deprecated: 15, message: "`AsyncSequence.Failure` is available, so use the `any` keyword")
@available(tvOS, deprecated: 18, message: "`AsyncSequence.Failure` is available, so use the `any` keyword")
@available(watchOS, deprecated: 11, message: "`AsyncSequence.Failure` is available, so use the `any` keyword")
public struct AnySendableAsyncSequence<Element>: Sendable {
    private let _makeAsyncIterator: @Sendable () -> AsyncIterator
    
    public init<Wrapped: AsyncSequence & Sendable>(_ wrapped: Wrapped) where Wrapped.Element == Element {
        _makeAsyncIterator = { .init(wrapped.makeAsyncIterator()) }
    }
}

extension AnySendableAsyncSequence: AsyncSequence {
    public struct AsyncIterator {
        private let _next: () async throws -> Element?
        
        init<Wrapped: AsyncIteratorProtocol>(_ wrapped: Wrapped) where Wrapped.Element == Element {
            var iterator = wrapped
            _next = { try await iterator.next() }
        }
    }
    
    public func makeAsyncIterator() -> AsyncIterator {
        _makeAsyncIterator()
    }
}

extension AnySendableAsyncSequence.AsyncIterator: AsyncIteratorProtocol {
    public mutating func next() async throws -> Element? {
        try await _next()
    }
}

public extension AsyncSequence where Self: Sendable {
    func eraseToAnySendableAsyncSequence() -> AnySendableAsyncSequence<Element> {
        .init(self)
    }
}
