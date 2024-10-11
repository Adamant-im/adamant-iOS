//
//  AsyncSequence+Extension.swift
//  CommonKit
//
//  Created by Andrew G on 09.10.2024.
//

import Combine

public extension AsyncSequence where Self: Sendable {
    func sink(receiveValue: @escaping @Sendable (Element) async -> Void) -> AnyCancellable {
        Task {
            for try await newValue in self {
                await receiveValue(newValue)
            }
        }.eraseToAnyCancellable()
    }
}
