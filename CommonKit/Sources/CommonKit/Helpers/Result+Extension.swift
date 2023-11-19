//
//  Result+Extension.swift
//  
//
//  Created by Andrew G on 13.11.2023.
//

public extension Result {
    func asyncMap<NewSuccess>(
        _ transform: @escaping (Success) async -> NewSuccess
    ) async -> Result<NewSuccess, Failure> {
        switch self {
        case let .success(value):
            return await .success(transform(value))
        case let .failure(error):
            return .failure(error)
        }
    }
}
