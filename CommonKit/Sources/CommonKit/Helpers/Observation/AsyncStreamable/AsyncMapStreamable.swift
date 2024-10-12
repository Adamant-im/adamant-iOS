//
//  AsyncMapStreamable.swift
//  CommonKit
//
//  Created by Andrew G on 12.10.2024.
//

import Foundation

public struct AsyncMapStreamable<
    WrappedStreamable: AsyncStreamable,
    NewProducedSequence: AsyncSequence
>: AsyncStreamable where NewProducedSequence.Element: Sendable {
    private let wrappedStreamable: WrappedStreamable
    private let transformation: @Sendable (WrappedStreamable.ProducedSequence) -> NewProducedSequence
    
    public init(
        wrappedStreamable: WrappedStreamable,
        transformation: @escaping @Sendable (WrappedStreamable.ProducedSequence) -> NewProducedSequence
    ) {
        self.wrappedStreamable = wrappedStreamable
        self.transformation = transformation
    }
    
    public func makeSequence() -> NewProducedSequence {
        transformation(wrappedStreamable.makeSequence())
    }
}

public extension AsyncStreamable {
    func map<NewProducedSequence>(
        _ transformation: @escaping @Sendable (ProducedSequence) -> NewProducedSequence
    ) -> AsyncMapStreamable<Self, NewProducedSequence> {
        .init(wrappedStreamable: self, transformation: transformation)
    }
}
