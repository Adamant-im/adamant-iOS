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
import Web3Core

class EthApiService: WalletApiService {
    let api: BlockchainHealthCheckWrapper<EthApiCore>
    
    var keystoreManager: KeystoreManager? {
        get async { await api.service.keystoreManager }
    }
    
    var preferredNodeIds: [UUID] {
        api.preferredNodeIds
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
        await api.request { core, node in
            await core.performRequest(node: node, request)
        }
    }
    
    func requestApiCore<Output>(
        _ request: @Sendable @escaping (APICoreProtocol, Node) async -> ApiServiceResult<Output>
    ) async -> WalletServiceResult<Output> {
        await api.request { core, node in
            await request(core.apiCore, node).mapError { $0.asWalletServiceError() }
        }
    }
    
    func getStatusInfo() async -> WalletServiceResult<NodeStatusInfo> {
        await api.request { core, node in
            await core.getStatusInfo(node: node)
        }
    }
    
    func setKeystoreManager(_ keystoreManager: KeystoreManager) async {
        await api.service.setKeystoreManager(keystoreManager)
    }
}
