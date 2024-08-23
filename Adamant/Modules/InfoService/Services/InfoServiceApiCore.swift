//
//  InfoServiceApiCore.swift
//  Adamant
//
//  Created by Andrew G on 23.08.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import Foundation
import CommonKit

final class InfoServiceApiCore {
    private let apiCore: APICoreProtocol
    private let mapper: InfoServiceMapperProtocol
    
    init(
        apiCore: APICoreProtocol,
        mapper: InfoServiceMapperProtocol
    ) {
        self.apiCore = apiCore
        self.mapper = mapper
    }
    
    func getNodeStatus(
        origin: NodeOrigin
    ) async -> ApiServiceResult<InfoServiceStatusDTO> {
        await apiCore.sendRequestJsonResponse(
            origin: origin,
            path: InfoServiceApiCommands.status
        )
    }
}

extension InfoServiceApiCore: BlockchainHealthCheckableService {
    func getStatusInfo(
        origin: NodeOrigin
    ) async -> ApiServiceResult<NodeStatusInfo> {
        let startTimestamp = Date.now.timeIntervalSince1970
        let statusResponse = await getNodeStatus(origin: origin)
        let ping = Date.now.timeIntervalSince1970 - startTimestamp
        
        return statusResponse.map { statusDto in
            mapper.mapToNodeStatusInfo(
                ping: ping,
                status: mapper.mapToModel(statusDto)
            )
        }
    }
}
