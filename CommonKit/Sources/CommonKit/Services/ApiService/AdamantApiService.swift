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
        timeout: TimeInterval? = nil,
        _ request: @Sendable (APICoreProtocol, NodeOrigin) async -> ApiServiceResult<Output>
    ) async -> ApiServiceResult<Output> {
        if let timeout {
            await service.request(
                waitsForConnectivity: waitsForConnectivity,
                timeout: timeout
            ) { admApiCore, origin in
                await request(admApiCore.apiCore, origin)
            }
        } else {
            await service.request(
                waitsForConnectivity: waitsForConnectivity
            ) { admApiCore, origin in
                await request(admApiCore.apiCore, origin)
            }
        }
    }
}

extension AdamantApiServiceProtocol {
    public func sendTransaction(
        path: String,
        transaction: UnregisteredTransaction
    ) async -> ApiServiceResult<UInt64> {
        await sendTransaction(path: path, transaction: transaction, timeout: nil)
    }
}

extension AdamantApiService: AdamantApiServiceProtocol {
    @MainActor
    public var nodesInfoPublisher: AnyObservable<NodesListInfo> { service.nodesInfoPublisher }
    
    @MainActor
    public var nodesInfo: NodesListInfo { service.nodesInfo }
    
    public func healthCheck() { service.healthCheck() }
}
