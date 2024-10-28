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
        waitsForConnectivity: Bool = false,
        _ request: @Sendable (APICoreProtocol, NodeOrigin) async -> ApiServiceResult<Output>
    ) async -> ApiServiceResult<Output> {
        await service.request(
            waitsForConnectivity: waitsForConnectivity
        ) { admApiCore, origin in
            await request(admApiCore.apiCore, origin)
        }
    }
}

extension AdamantApiService: AdamantApiServiceProtocol {
    @MainActor
    public var nodesInfoPublisher: AnyObservable<NodesListInfo> { service.nodesInfoPublisher }
    
    @MainActor
    public var nodesInfo: NodesListInfo { service.nodesInfo }
    
    public func healthCheck() { service.healthCheck() }
}
