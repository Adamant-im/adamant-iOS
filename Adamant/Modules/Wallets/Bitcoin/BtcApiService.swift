//
//  BtcApiService.swift
//  Adamant
//
//  Created by Andrew G on 12.11.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import CommonKit
import Foundation

final class BtcApiCore: BlockchainHealthCheckableService {
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
        
        let response = await apiCore.sendRequestRPC(
            origin: origin,
            path: BtcApiCommands.getRPC(),
            requests: [
                .init(method: BtcApiCommands.blockchainInfoMethod),
                .init(method: BtcApiCommands.networkInfoMethod)
            ]
        )

        guard case let .success(data) = response else {
            return .failure(.internalError(.parsingFailed))
        }
        
        let networkInfoModel = data.first(
            where: { $0.id == BtcApiCommands.networkInfoMethod }
        )
        
        let blockchainInfoModel = data.first(
            where: { $0.id == BtcApiCommands.blockchainInfoMethod }
        )
        
        guard
            let networkInfo: BtcNetworkInfoDTO = networkInfoModel?.serialize(),
            let blockchainInfo: BtcBlockchainInfoDTO = blockchainInfoModel?.serialize()
        else {
            return .failure(.internalError(.parsingFailed))
        }
        
        return .success(.init(
            ping: Date.now.timeIntervalSince1970 - startTimestamp,
            height: blockchainInfo.blocks,
            wsEnabled: false,
            wsPort: nil,
            version: String(networkInfo.version)
        ))
    }
}

final class BtcApiService: ApiServiceProtocol {
    let api: BlockchainHealthCheckWrapper<BtcApiCore>
    
    var chosenFastestNodeId: UUID? {
        api.chosenFastestNodeId
    }
    
    var hasActiveNode: Bool {
        !api.sortedAllowedNodes.isEmpty
    }
    
    init(api: BlockchainHealthCheckWrapper<BtcApiCore>) {
        self.api = api
    }
    
    func healthCheck() {
        api.healthCheck()
    }
    
    func request<Output>(
        _ request: @Sendable @escaping (APICoreProtocol, NodeOrigin) async -> ApiServiceResult<Output>
    ) async -> WalletServiceResult<Output> {
        await api.request { core, origin in
            await core.request(origin: origin, request)
        }
    }
    
    func getStatusInfo() async -> WalletServiceResult<NodeStatusInfo> {
        await api.request { core, origin in
            await core.getStatusInfo(origin: origin)
        }
    }
}
