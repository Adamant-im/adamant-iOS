//
//  AsyncMapStreamable.swift
//  CommonKit
//
//  Created by Andrew G on 12.10.2024.
//

import Foundation

public struct AsyncMapStreamable<
    Wrapped: AsyncStreamable,
    NewProducedSequence: AsyncSequence & Sendable
>: AsyncStreamable where NewProducedSequence.Element: Sendable {
    private let wrapped: Wrapped
    private let transformation: @Sendable (Wrapped.ProducedSequence) -> NewProducedSequence
    
    public init(
        wrapped: Wrapped,
        transformation: @escaping @Sendable (Wrapped.ProducedSequence) -> NewProducedSequence
    ) {
        self.wrapped = wrapped
        self.transformation = transformation
    }
    
    public func makeSequence() -> NewProducedSequence {
        transformation(wrapped.makeSequence())
    }
}

public extension AsyncStreamable {
    func map<NewProducedSequence>(
        _ transformation: @escaping @Sendable (ProducedSequence) -> NewProducedSequence
    ) -> AsyncMapStreamable<Self, NewProducedSequence> {
        .init(wrapped: self, transformation: transformation)
    }
}
