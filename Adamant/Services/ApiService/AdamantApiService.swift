//
//  AdamantApiService.swift
//  Adamant
//
//  Created by Anokhov Pavel on 06.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import CommonKit
import Foundation

final class AdamantApiService {
    let adamantCore: AdamantCore
    let service: BlockchainHealthCheckWrapper<AdamantApiCore>
    
    init(
        healthCheckWrapper: BlockchainHealthCheckWrapper<AdamantApiCore>,
        adamantCore: AdamantCore
    ) {
        service = healthCheckWrapper
        self.adamantCore = adamantCore
    }
    
    func request<Output>(
        _ request: @Sendable (APICoreProtocol, Node) async -> ApiServiceResult<Output>
    ) async -> ApiServiceResult<Output> {
        await service.request { admApiCore, node in
            await request(admApiCore.apiCore, node)
        }
    }
}

extension AdamantApiService: ApiService {
    var preferredNodeIds: [UUID] {
        service.preferredNodeIds
    }
    
    func healthCheck() {
        service.healthCheck()
    }
}
