//
//  EthApiService.swift
//  Adamant
//
//  Created by Andrew G on 13.11.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import CommonKit
import Foundation
import web3swift
@preconcurrency import Web3Core

class EthApiService: ApiServiceProtocol, @unchecked Sendable {
    let api: BlockchainHealthCheckWrapper<EthApiCore>
    
    var keystoreManager: KeystoreManager? {
        get async { await api.service.keystoreManager }
    }
    
    var chosenFastestNodeId: UUID? {
        api.chosenFastestNodeId
    }
    
    var hasActiveNode: Bool {
        !api.sortedAllowedNodes.isEmpty
    }
    
    init(api: BlockchainHealthCheckWrapper<EthApiCore>) {
        self.api = api
    }
    
    func healthCheck() {
        api.healthCheck()
    }
    
    func requestWeb3<Output>(
        _ request: @Sendable @escaping (Web3) async throws -> Output
    ) async -> WalletServiceResult<Output> {
        await api.request { core, origin in
            await core.performRequest(origin: origin, request)
        }
    }
    
    func requestApiCore<Output>(
        _ request: @Sendable @escaping (APICoreProtocol, NodeOrigin) async -> ApiServiceResult<Output>
    ) async -> WalletServiceResult<Output> {
        await api.request { core, origin in
            await request(core.apiCore, origin).mapError { $0.asWalletServiceError() }
        }
    }
    
    func getStatusInfo() async -> WalletServiceResult<NodeStatusInfo> {
        await api.request { core, origin in
            await core.getStatusInfo(origin: origin)
        }
    }
    
    func setKeystoreManager(_ keystoreManager: KeystoreManager) async {
        await api.service.setKeystoreManager(keystoreManager)
    }
}
