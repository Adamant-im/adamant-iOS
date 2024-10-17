//
//  AnyAsyncStreamable.swift
//  CommonKit
//
//  Created by Andrew G on 13.10.2024.
//

import Foundation

@available(iOS, deprecated: 18, message: "`AsyncSequence.Failure` is available, so use the `any` keyword")
@available(macOS, deprecated: 15, message: "`AsyncSequence.Failure` is available, so use the `any` keyword")
@available(tvOS, deprecated: 18, message: "`AsyncSequence.Failure` is available, so use the `any` keyword")
@available(watchOS, deprecated: 11, message: "`AsyncSequence.Failure` is available, so use the `any` keyword")
public struct AnyAsyncStreamable<Element: Sendable>: AsyncStreamable {
    private let _makeSequence: @Sendable () -> AnySendableAsyncSequence<Element>
    
    public init<Wrapped: AsyncStreamable>(_ wrapped: Wrapped) where Wrapped.Element == Element {
        _makeSequence = { wrapped.makeSequence().eraseToAnySendableAsyncSequence() }
    }
    
    public func makeSequence() -> AnySendableAsyncSequence<Element> {
        _makeSequence()
    }
}

public extension AsyncStreamable {
    func eraseToAnyAsyncStreamable() -> AnyAsyncStreamable<Element> {
        .init(self)
    }
}
