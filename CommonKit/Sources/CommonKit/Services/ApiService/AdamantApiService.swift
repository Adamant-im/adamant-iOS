//
//  AdamantApiService.swift
//  Adamant
//
//  Created by Anokhov Pavel on 06.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

public final class AdamantApiService {
    public let adamantCore: AdamantCore
    public let service: BlockchainHealthCheckWrapper<AdamantApiCore>
    
    public init(
        healthCheckWrapper: BlockchainHealthCheckWrapper<AdamantApiCore>,
        adamantCore: AdamantCore
    ) {
        service = healthCheckWrapper
        self.adamantCore = adamantCore
    }
    
    public func request<Output>(
        _ request: @Sendable (APICoreProtocol, NodeOrigin) async -> ApiServiceResult<Output>
    ) async -> ApiServiceResult<Output> {
        await service.request { admApiCore, origin in
            await request(admApiCore.apiCore, origin)
        }
    }
}

extension AdamantApiService: AdamantApiServiceProtocol {
    public var chosenFastestNodeId: UUID? {
        service.chosenFastestNodeId
    }
    
    public func healthCheck() {
        service.healthCheck()
    }
    
    public var hasActiveNode: Bool {
        !service.sortedAllowedNodes.isEmpty
    }
}
