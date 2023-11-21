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
        node: Node,
        _ request: @Sendable @escaping (APICoreProtocol, Node) async -> ApiServiceResult<Output>
    ) async -> WalletServiceResult<Output> {
        await request(apiCore, node).mapError { $0.asWalletServiceError() }
    }

    func getStatusInfo(node: Node) async -> WalletServiceResult<NodeStatusInfo> {
        let startTimestamp = Date.now.timeIntervalSince1970
        
        let response: WalletServiceResult<DogeBlocksDTO> = await request(node: node) { core, node in
            await core.sendRequestJson(
                node: node,
                path: DogeApiCommands.getBlocks(),
                method: .get,
                parameters: ["limit": 0],
                encoding: .url
            )
        }

        return response.map { data in
            return .init(
                ping: Date.now.timeIntervalSince1970 - startTimestamp,
                height: data.blocks.first?.height ?? .zero,
                wsEnabled: false,
                wsPort: nil,
                version: nil
            )
        }
    }
}

final class DogeApiService: WalletApiService {
    let api: BlockchainHealthCheckWrapper<DogeApiCore>
    
    var preferredNodeIds: [UUID] {
        api.preferredNodeIds
    }
    
    init(api: BlockchainHealthCheckWrapper<DogeApiCore>) {
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
