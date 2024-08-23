//
//  InfoServiceApiService.swift
//  Adamant
//
//  Created by Andrew G on 23.08.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import Foundation
import CommonKit

public final class InfoServiceApiService {
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

extension InfoServiceApiService: ApiServiceProtocol {
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

