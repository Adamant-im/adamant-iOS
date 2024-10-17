//
//  AsyncSequence+Extension.swift
//  CommonKit
//
//  Created by Andrew G on 09.10.2024.
//

import Combine

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
}
