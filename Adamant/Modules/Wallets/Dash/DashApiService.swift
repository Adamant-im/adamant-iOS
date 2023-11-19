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
        
        let response: WalletServiceResult<DashBlockchainInfoDTO> = await request(node: node) { core, node in
            let response: ApiServiceResult<DashResponseDTO<DashBlockchainInfoDTO>> = await core.sendRequestJson(
                node: node,
                path: .empty,
                method: .post,
                parameters: ["method": "getblockchaininfo"],
                encoding: .json
            )
            
            return response.flatMap { dto in
                if let result = dto.result, dto.error == nil {
                    return .success(result)
                } else {
                    return .failure(.serverError(error: dto.error?.localizedDescription ?? .empty))
                }
            }
        }

        return response.map { data in
            return .init(
                ping: Date.now.timeIntervalSince1970 - startTimestamp,
                height: data.blocks,
                wsEnabled: false,
                wsPort: nil,
                version: nil
            )
        }
    }
}

final class DashApiService {
    let api: BlockchainHealthCheckWrapper<DashApiCore>
    
    init(api: BlockchainHealthCheckWrapper<DashApiCore>) {
        self.api = api
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
