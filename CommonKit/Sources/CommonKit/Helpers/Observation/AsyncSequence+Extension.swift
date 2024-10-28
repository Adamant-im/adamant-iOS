//
//  AsyncSequence+Extension.swift
//  CommonKit
//
//  Created by Andrew G on 09.10.2024.
//

import Combine
import AsyncAlgorithms

public extension AsyncSequence where Self: Sendable {
    func sink(
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
    
    func combineLatest<T: AsyncSequence & Sendable>(_ other: T) -> AsyncCombineLatest2Sequence<Self, T> {
        AsyncAlgorithms.combineLatest(self, other)
    }
}

public extension AsyncSequence {
    var first: Element? {
        get async throws { try await first { _ in true } }
    }
    
    func handleEvents(receiveOutput: @escaping (Element) async throws -> Void) -> AsyncMapSequence<Self, Element> {
        map { [receiveOutput] in
            try? await receiveOutput($0)
            return $0
        }
    }
}
