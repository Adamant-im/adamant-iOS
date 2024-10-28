//
//  InfoServiceApiService.swift
//  Adamant
//
//  Created by Andrew G on 23.08.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import Foundation
import CommonKit

final class InfoServiceApiService: Sendable {
    let core: BlockchainHealthCheckWrapper<InfoServiceApiCore>
    let mapper: InfoServiceMapperProtocol
    
    func request<Output>(
        _ request: @Sendable (
            APICoreProtocol,
            NodeOrigin
        ) async -> ApiServiceResult<Output>
    ) async -> InfoServiceApiResult<Output> {
        await core.request(waitsForConnectivity: false) { core, origin in
            await request(core.apiCore, origin)
        }.mapError { .apiError($0) }
    }
    
    init(core: BlockchainHealthCheckWrapper<InfoServiceApiCore>, mapper: InfoServiceMapperProtocol) {
        self.core = core
        self.mapper = mapper
    }
}
