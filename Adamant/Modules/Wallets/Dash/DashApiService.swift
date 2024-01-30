//
//  DashApiService.swift
//  Adamant
//
//  Created by Andrew G on 17.11.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import CommonKit
import Foundation

final class DashApiCore: BlockchainHealthCheckableService {
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
        
        let response = await apiCore.sendRequestRPCArrayResponse(
            node: node,
            path: .empty,
            methods: [DashApiComand.networkInfoMethod, DashApiComand.blockchainInfoMethod]
        )
        
        guard case let .success(data) = response else {
            return .failure(.internalError(.parsingFailed))
        }
        
        let networkInfoData = data[DashApiComand.networkInfoMethod]
        let blockchainInfoData = data[DashApiComand.blockchainInfoMethod]
        
        guard
            let networkInfoData = networkInfoData,
            let blockchainInfoData = blockchainInfoData,
            let blockchainInfo = try? JSONDecoder().decode(DashBlockchainInfoDTO.self, from: blockchainInfoData),
            let networkInfo = try? JSONDecoder().decode(DashNetworkInfoDTO.self, from: networkInfoData)
        else {
            return .failure(.internalError(.parsingFailed))
        }
        
        return .success(.init(
            ping: Date.now.timeIntervalSince1970 - startTimestamp,
            height: blockchainInfo.blocks,
            wsEnabled: false,
            wsPort: nil,
            version: networkInfo.buildversion
        ))
    }
}

final class DashApiService: WalletApiService {
    let api: BlockchainHealthCheckWrapper<DashApiCore>
    
    var preferredNodeIds: [UUID] {
        api.preferredNodeIds
    }
    
    init(api: BlockchainHealthCheckWrapper<DashApiCore>) {
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

private struct DashApiComand {
    static let networkInfoMethod: String = "getnetworkinfo"
    static let blockchainInfoMethod: String = "getblockchaininfo"
}
