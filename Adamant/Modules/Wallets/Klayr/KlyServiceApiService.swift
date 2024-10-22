//
//  KlyServiceApiService.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 08.07.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

@preconcurrency import LiskKit
import Foundation
import CommonKit

final class KlyServiceApiCore: KlyApiCore {
    override func getStatusInfo(
        origin: NodeOrigin
    ) async -> WalletServiceResult<NodeStatusInfo> {
        let startTimestamp = Date.now.timeIntervalSince1970
        
        return await request(origin: origin) { client in
            let service = LiskKit.Service(client: client)
            return try await (fee: service.fees(), info: service.info())
        }.map { model in
            .init(
                ping: Date.now.timeIntervalSince1970 - startTimestamp,
                height: .init(model.fee.meta.lastBlockHeight),
                wsEnabled: false,
                wsPort: nil,
                version: .init(model.info.version)
            )
        }
    }
}

final class KlyServiceApiService: ApiServiceProtocol {
    let api: BlockchainHealthCheckWrapper<KlyServiceApiCore>
    
    var chosenFastestNodeId: UUID? {
        api.chosenFastestNodeId
    }
    
    var hasActiveNode: Bool {
        !api.sortedAllowedNodes.isEmpty
    }
    
    init(api: BlockchainHealthCheckWrapper<KlyServiceApiCore>) {
        self.api = api
    }
    
    func healthCheck() {
        api.healthCheck()
    }
    
    func requestServiceApi<Output>(
        waitsForConnectivity: Bool,
        body: @escaping @Sendable (
            _ api: LiskKit.Service,
            _ completion: @escaping @Sendable (LiskKit.Result<Output>) -> Void
        ) -> Void
    ) async -> WalletServiceResult<Output> {
        await requestClient(waitsForConnectivity: waitsForConnectivity) { client, completion in
            body(.init(client: client, version: .v3), completion)
        }
    }
    
    func requestServiceApi<Output>(
        waitsForConnectivity: Bool,
        _ request: @Sendable @escaping (LiskKit.Service) async throws -> Output
    ) async -> WalletServiceResult<Output> {
        await requestClient(waitsForConnectivity: waitsForConnectivity) { client in
            try await request(LiskKit.Service(client: client, version: .v3))
        }
    }
}

private extension KlyServiceApiService {
    func requestClient<Output>(
        waitsForConnectivity: Bool,
        body: @escaping @Sendable (
            _ client: APIClient,
            _ completion: @escaping @Sendable (LiskKit.Result<Output>) -> Void
        ) -> Void
    ) async -> WalletServiceResult<Output> {
        await api.request(waitsForConnectivity: waitsForConnectivity) { core, origin in
            await core.request(origin: origin, body: body)
        }
    }
    
    func requestClient<Output>(
        waitsForConnectivity: Bool,
        _ body: @Sendable @escaping (APIClient) async throws -> Output
    ) async -> WalletServiceResult<Output> {
        await api.request(waitsForConnectivity: waitsForConnectivity) { core, origin in
            await core.request(origin: origin, body)
        }
    }
}
