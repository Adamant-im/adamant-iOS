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
    
    func getNodeStatus(origin: NodeOrigin) async -> ApiServiceResult<IPFSNodeStatus> {
        await apiCore.sendRequestJsonResponse(
            origin: origin,
            path: IPFSApiCommands.status
        )
    }
}

extension IPFSApiCore: BlockchainHealthCheckableService {
    func getStatusInfo(origin: NodeOrigin) async -> ApiServiceResult<NodeStatusInfo> {
        let startTimestamp = Date.now.timeIntervalSince1970
        let statusResponse = await getNodeStatus(origin: origin)
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
