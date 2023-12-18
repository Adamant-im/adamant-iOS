//
//  LskServiceApiService.swift
//  Adamant
//
//  Created by Andrew G on 17.11.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import LiskKit
import Foundation
import CommonKit

final class LskServiceApiCore: LskApiCore {
    override func getStatusInfo(
        node: CommonKit.Node
    ) async -> WalletServiceResult<NodeStatusInfo> {
        let startTimestamp = Date.now.timeIntervalSince1970
        
        return await request(node: node) { client, completion in
            LiskKit.Service(client: client).getFees { completion($0) }
        }.map { model in
            .init(
                ping: Date.now.timeIntervalSince1970 - startTimestamp,
                height: .init(model.meta.lastBlockHeight),
                wsEnabled: false,
                wsPort: nil,
                version: nil
            )
        }
    }
}

final class LskServiceApiService: WalletApiService {
    let api: BlockchainHealthCheckWrapper<LskServiceApiCore>
    
    var preferredNodeIds: [UUID] {
        api.preferredNodeIds
    }
    
    init(api: BlockchainHealthCheckWrapper<LskServiceApiCore>) {
        self.api = api
    }
    
    func healthCheck() {
        api.healthCheck()
    }
    
    func requestServiceApi<Output>(
        body: @escaping @Sendable (
            _ api: LiskKit.Service,
            _ completion: @escaping @Sendable (LiskKit.Result<Output>) -> Void
        ) -> Void
    ) async -> WalletServiceResult<Output> {
        await requestClient { client, completion in
            body(.init(client: client, version: .v2), completion)
        }
    }
}

private extension LskServiceApiService {
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
