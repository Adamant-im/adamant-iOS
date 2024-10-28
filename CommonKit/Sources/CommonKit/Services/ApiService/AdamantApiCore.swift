//
//  AdamantApiCore.swift
//  Adamant
//
//  Created by Andrew G on 31.10.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation
import Alamofire

public extension ApiCommands {
    static let status = "/api/node/status"
    static let version = "/api/peers/version"
}

public final class AdamantApiCore: Sendable {
    public let apiCore: APICoreProtocol
    
    public init(apiCore: APICoreProtocol) {
        self.apiCore = apiCore
    }
    
    public func getNodeStatus(
        origin: NodeOrigin
    ) async -> ApiServiceResult<NodeStatus> {
        await apiCore.sendRequestJsonResponse(
            origin: origin,
            path: ApiCommands.status
        )
    }
}

extension AdamantApiCore: BlockchainHealthCheckableService {
    public func getStatusInfo(
        origin: NodeOrigin
    ) async -> ApiServiceResult<NodeStatusInfo> {
        let startTimestamp = Date.now.timeIntervalSince1970
        let statusResponse = await getNodeStatus(origin: origin)
        let ping = Date.now.timeIntervalSince1970 - startTimestamp
        
        return statusResponse.map { statusDto in
            .init(
                ping: ping,
                height: statusDto.network?.height ?? .zero,
                wsEnabled: statusDto.wsClient?.enabled ?? false,
                wsPort: statusDto.wsClient?.port,
                version: statusDto.version?.version.flatMap { .init($0) }
            )
        }
    }
}
