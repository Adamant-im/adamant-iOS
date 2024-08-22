//
//  IPFSApiCore.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 09.04.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import Foundation
import CommonKit

extension IPFSApiCommands {
    static let status = "/api/node/info"
}

final class IPFSApiCore {
    let apiCore: APICoreProtocol
    
    init(apiCore: APICoreProtocol) {
        self.apiCore = apiCore
    }
    
    func getNodeStatus(node: Node) async -> ApiServiceResult<IPFSNodeStatus> {
        await apiCore.sendRequestJsonResponse(
            node: node,
            path: IPFSApiCommands.status
        )
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
