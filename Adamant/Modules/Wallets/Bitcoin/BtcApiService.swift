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
        node: Node,
        _ request: @Sendable @escaping (APICoreProtocol, Node) async -> ApiServiceResult<Output>
    ) async -> WalletServiceResult<Output> {
        await request(apiCore, node).mapError { $0.asWalletServiceError() }
    }

    func getStatusInfo(node: Node) async -> WalletServiceResult<NodeStatusInfo> {
        let startTimestamp = Date.now.timeIntervalSince1970
        
        let response = await apiCore.sendRequestRPC(
            node: node,
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

final class BtcApiService: WalletApiService {
    let api: BlockchainHealthCheckWrapper<BtcApiCore>
    
    var preferredNodeIds: [UUID] {
        api.preferredNodeIds
    }
    
    init(api: BlockchainHealthCheckWrapper<BtcApiCore>) {
        self.api = api
    }
    
    func healthCheck() {
        api.healthCheck()
    }
    
    func request<Output>(
        _ request: @Sendable @escaping (APICoreProtocol, Node) async -> ApiServiceResult<Output>
    ) async -> WalletServiceResult<Output> {
        await api.request { core, node in
            await core.request(node: node, request)
        }
    }
    
    func getStatusInfo() async -> WalletServiceResult<NodeStatusInfo> {
        await api.request { core, node in
            await core.getStatusInfo(node: node)
        }
    }
}
