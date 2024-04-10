//
//  IPFSApiCore.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 09.04.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import Foundation
import CommonKit

final class IPFSApiCore {
    let apiCore: APICoreProtocol
    
    init(apiCore: APICoreProtocol) {
        self.apiCore = apiCore
    }
    
    func getNodeStatus(node: Node) async -> ApiServiceResult<NodeStatus> {
        await Task.sleep(interval: Double.random(in: 0.1...1))
        return .success(.init(
            success: true,
            nodeTimestamp: Date().timeIntervalSince1970,
            network: nil,
            version: nil,
            wsClient: nil
        ))
    }
}

extension IPFSApiCore: BlockchainHealthCheckableService {
    func getStatusInfo(node: Node) async -> ApiServiceResult<NodeStatusInfo> {
        let startTimestamp = Date.now.timeIntervalSince1970
        let statusResponse = await getNodeStatus(node: node)
        let ping = Date.now.timeIntervalSince1970 - startTimestamp
        
        return statusResponse.map { _ in
            .init(
                ping: ping,
                height: .zero,
                wsEnabled: false,
                wsPort: nil,
                version: nil
            )
        }
    }
}
