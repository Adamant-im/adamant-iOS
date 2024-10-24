//
//  HealthCheckWrapper+Extension.swift
//  CommonKit
//
//  Created by Andrew G on 21.10.2024.
//

import Foundation

extension HealthCheckWrapper: ApiServiceProtocol {
    nonisolated public var chosenFastestNodeId: AnyAsyncStreamable<UUID?> {
        sortedAllowedNodes.map { $0.map { $0.first?.id } }.eraseToAnyAsyncStreamable()
    }
    
    nonisolated public var hasActiveNode: AnyAsyncStreamable<Bool> {
        sortedAllowedNodes.map { $0.map { $0.isEmpty } }.eraseToAnyAsyncStreamable()
    }
}
