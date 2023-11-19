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
        
        let response = await request(node: node) { core, node in
            await core.sendRequest(node: node, path: BtcApiCommands.getHeight())
        }

        return response.flatMap { data in
            guard
                let raw = String(data: data, encoding: .utf8),
                let height = Int(string: raw)
            else {
                return .failure(.internalError(.parsingFailed))
            }
            
            return .success(.init(
                ping: Date.now.timeIntervalSince1970 - startTimestamp,
                height: height,
                wsEnabled: false,
                wsPort: nil,
                version: nil
            ))
        }
    }
}

final class BtcApiService {
    let api: BlockchainHealthCheckWrapper<BtcApiCore>
    
    init(api: BlockchainHealthCheckWrapper<BtcApiCore>) {
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
