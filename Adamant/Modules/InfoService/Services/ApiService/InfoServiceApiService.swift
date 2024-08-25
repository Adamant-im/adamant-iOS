//
//  InfoServiceApiService.swift
//  Adamant
//
//  Created by Andrew G on 23.08.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import Foundation
import CommonKit

struct InfoServiceApiService {
    let core: BlockchainHealthCheckWrapper<InfoServiceApiCore>
    
    func request<Output>(
        _ request: @Sendable (
            APICoreProtocol,
            NodeOrigin
        ) async -> ApiServiceResult<Output>
    ) async -> InfoServiceApiResult<Output> {
        await core.request { core, origin in
            await request(core.apiCore, origin)
        }.mapError { .apiError($0) }
    }
}
