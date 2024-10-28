//
//  ApiServiceProtocol.swift
//  Adamant
//
//  Created by Andrew G on 20.11.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation

public protocol ApiServiceProtocol: Sendable {
    @MainActor
    var nodesInfo: NodesListInfo { get }
    
    @MainActor
    var nodesInfoPublisher: AnyObservable<NodesListInfo> { get }
    
    func healthCheck()
}

public extension ApiServiceProtocol {
    @MainActor
    var hasEnabledNodePublisher: AnyObservable<Bool> {
        nodesInfoPublisher
            .map { $0.nodes.contains { $0.isEnabled } }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
    
    @MainActor
    var hasEnabledNode: Bool {
        nodesInfo.nodes.contains { $0.isEnabled }
    }
}
