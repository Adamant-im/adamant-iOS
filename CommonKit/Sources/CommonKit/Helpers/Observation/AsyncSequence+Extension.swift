//
//  AsyncSequence+Extension.swift
//  CommonKit
//
//  Created by Andrew G on 09.10.2024.
//

import AsyncAlgorithms
import Combine

extension AsyncSequence where Self: Sendable {
    public func sink(
        receiveValue: @escaping @Sendable (Element) async -> Void,
        receiveCompletion: @escaping @Sendable (Error?) async -> Void = { _ in }
    ) -> AnyCancellable {
        Task {
            do {
                for try await newValue in self {
                    await receiveValue(newValue)
                }

                await receiveCompletion(nil)
            } catch {
                await receiveCompletion(error)
            }
        }.eraseToAnyCancellable()
    }

    public func combineLatest<T: AsyncSequence & Sendable>(_ other: T) -> AsyncCombineLatest2Sequence<Self, T> {
        AsyncAlgorithms.combineLatest(self, other)
    }
}

extension AsyncSequence {
    public var first: Element? {
        get async throws { try await first { _ in true } }
    }

    public func handleEvents(receiveOutput: @escaping (Element) async throws -> Void) -> AsyncMapSequence<Self, Element> {
        map { [receiveOutput] in
            try? await receiveOutput($0)
            return $0
        }
    }
}
