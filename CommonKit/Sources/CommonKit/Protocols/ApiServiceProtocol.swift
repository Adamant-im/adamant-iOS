//
//  ApiServiceProtocol.swift
//  Adamant
//
//  Created by Andrew G on 20.11.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation

public protocol ApiServiceProtocol: Sendable {
    var chosenFastestNodeId: AnyAsyncStreamable<UUID?> { get }
    var hasActiveNode: AnyAsyncStreamable<Bool> { get }
    
    func healthCheck()
}

public extension ApiServiceProtocol {
    var chosenFastestNodeId: UUID? {
        get async { try? await chosenFastestNodeId.makeSequence().first?.flatMap { $0 } }
    }
    
    var hasActiveNode: Bool {
        get async { (try? await hasActiveNode.makeSequence().first) ?? false }
    }
}
