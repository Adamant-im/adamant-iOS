//
//  KlyNodeApiService.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 08.07.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import LiskKit
import Foundation
import CommonKit

final class KlyNodeApiService: ApiServiceProtocol {
    let api: BlockchainHealthCheckWrapper<KlyApiCore>
    
    var chosenFastestNodeId: UUID? {
        api.chosenFastestNodeId
    }
    
    var hasActiveNode: Bool {
        !api.sortedAllowedNodes.isEmpty
    }
    
    init(api: BlockchainHealthCheckWrapper<KlyApiCore>) {
        self.api = api
    }
    
    func healthCheck() {
        api.healthCheck()
    }
    
    func requestNodeApi<Output>(
        body: @escaping @Sendable (
            _ api: LiskKit.Node,
            _ completion: @escaping @Sendable (LiskKit.Result<Output>) -> Void
        ) -> Void
    ) async -> WalletServiceResult<Output> {
        await requestClient { client, completion in
            body(.init(client: client), completion)
        }
    }
    
    func requestTransactionsApi<Output>(
        _ request: @Sendable @escaping (Transactions) async throws -> Output
    ) async -> WalletServiceResult<Output> {
        await requestClient { client in
            try await request(Transactions(client: client))
        }
    }
    
    func requestAccountsApi<Output>(
        _ request: @Sendable @escaping (Accounts) async throws -> Output
    ) async -> WalletServiceResult<Output> {
        await requestClient { client in
            try await request(Accounts(client: client))
        }
    }
    
    func getStatusInfo() async -> WalletServiceResult<NodeStatusInfo> {
        await api.request { core, origin in
            await core.getStatusInfo(origin: origin)
        }
    }
}

private extension KlyNodeApiService {
    func requestClient<Output>(
        body: @escaping @Sendable (
            _ client: APIClient,
            _ completion: @escaping @Sendable (LiskKit.Result<Output>) -> Void
        ) -> Void
    ) async -> WalletServiceResult<Output> {
        await api.request { core, origin in
            await core.request(origin: origin, body: body)
        }
    }
    
    func requestClient<Output>(
        _ body: @Sendable @escaping (APIClient) async throws -> Output
    ) async -> WalletServiceResult<Output> {
        await api.request { core, origin in
            await core.request(origin: origin, body)
        }
    }
}
