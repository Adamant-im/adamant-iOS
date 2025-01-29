//
//  Result+Extensions.swift
//  Adamant
//
//  Created by Christian Benua on 10.01.2025.
//  Copyright © 2025 Adamant. All rights reserved.
//

extension Result {
    var error: Failure? {
        switch self {
        case let .failure(error):
            return error
        case .success:
            return nil
        }
    }
    
    var value: Success? {
        switch self {
        case .failure:
            return nil
        case let .success(value):
            return value
        }
    }
}

extension Result where Failure == Error {
    init(catchingAsync run: @escaping () async throws -> Success) async {
        do {
            let value = try await run()
            self = .success(value)
        } catch {
            self = .failure(error)
        }
    }
}
