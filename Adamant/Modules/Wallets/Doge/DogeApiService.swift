//
//  DogeApiService.swift
//  Adamant
//
//  Created by Andrew G on 17.11.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import CommonKit
import Foundation

final class DogeApiCore: BlockchainHealthCheckableService {
    let apiCore: APICoreProtocol

    init(apiCore: APICoreProtocol) {
        self.apiCore = apiCore
    }
    
    func request<Output>(
        origin: NodeOrigin,
        _ request: @Sendable @escaping (APICoreProtocol, NodeOrigin) async -> ApiServiceResult<Output>
    ) async -> WalletServiceResult<Output> {
        await request(apiCore, origin).mapError { $0.asWalletServiceError() }
    }

    func getStatusInfo(origin: NodeOrigin) async -> WalletServiceResult<NodeStatusInfo> {
        let startTimestamp = Date.now.timeIntervalSince1970
        
        let response: WalletServiceResult<DogeNodeInfoDTO> = await request(origin: origin) { core, origin in
            await core.sendRequestJsonResponse(
                origin: origin,
                path: DogeApiCommands.getInfo()
            )
        }
        
        return response.map { data in
            return .init(
                ping: Date.now.timeIntervalSince1970 - startTimestamp,
                height: data.info.blocks,
                wsEnabled: false,
                wsPort: nil,
                version: .init([data.info.version])
            )
        }
    }
}

final class DogeApiService: ApiServiceProtocol {
    let api: BlockchainHealthCheckWrapper<DogeApiCore>
    
    var chosenFastestNodeId: UUID? {
        api.chosenFastestNodeId
    }
    
    var hasActiveNode: Bool {
        !api.sortedAllowedNodes.isEmpty
    }
    
    init(api: BlockchainHealthCheckWrapper<DogeApiCore>) {
        self.api = api
    }
    
    func healthCheck() {
        api.healthCheck()
    }
    
    func request<Output>(
        waitsForConnectivity: Bool,
        _ request: @Sendable @escaping (APICoreProtocol, NodeOrigin) async -> ApiServiceResult<Output>
    ) async -> WalletServiceResult<Output> {
        await api.request(waitsForConnectivity: waitsForConnectivity) { core, origin in
            await core.request(origin: origin, request)
        }
    }
    
    func getStatusInfo() async -> WalletServiceResult<NodeStatusInfo> {
        await api.request(waitsForConnectivity: false) { core, origin in
            await core.getStatusInfo(origin: origin)
        }
    }
}
