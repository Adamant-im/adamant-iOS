//
//  Publisher+Extension.swift
//  
//
//  Created by Andrey Golubenko on 16.08.2023.
//

import Combine

public extension Publisher where Failure == Never {
    func asyncSink(_ action: @Sendable @escaping (Output) async -> Void) -> AnyCancellable {
        sink { output in
            Task { await action(output) }
        }
    }
}
