//
//  LskNodeApiService.swift
//  Adamant
//
//  Created by Andrew G on 17.11.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import LiskKit
import Foundation

final class LskNodeApiService: WalletApiService {
    let api: BlockchainHealthCheckWrapper<LskApiCore>
    
    var preferredNodeIds: [UUID] {
        api.preferredNodeIds
    }
    
    init(api: BlockchainHealthCheckWrapper<LskApiCore>) {
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
        body: @escaping @Sendable (
            _ api: Transactions,
            _ completion: @escaping @Sendable (LiskKit.Result<Output>) -> Void
        ) -> Void
    ) async -> WalletServiceResult<Output> {
        await requestClient { client, completion in
            body(.init(client: client), completion)
        }
    }
    
    func requestAccountsApi<Output>(
        body: @escaping @Sendable (
            _ api: Accounts,
            _ completion: @escaping @Sendable (LiskKit.Result<Output>) -> Void
        ) -> Void
    ) async -> WalletServiceResult<Output> {
        await requestClient { client, completion in
            body(.init(client: client), completion)
        }
    }
    
    func getStatusInfo() async -> WalletServiceResult<NodeStatusInfo> {
        await api.request { core, node in
            await core.getStatusInfo(node: node)
        }
    }
}

private extension LskNodeApiService {
    func requestClient<Output>(
        body: @escaping @Sendable (
            _ client: APIClient,
            _ completion: @escaping @Sendable (LiskKit.Result<Output>) -> Void
        ) -> Void
    ) async -> WalletServiceResult<Output> {
        await api.request { core, node in
            await core.request(node: node, body: body)
        }
    }
}
