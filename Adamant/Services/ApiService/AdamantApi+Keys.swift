//
//  AdamantApi+Keys.swift
//  Adamant
//
//  Created by Anokhov Pavel on 24.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import CommonKit

extension AdamantApiService {
    func getPublicKey(byAddress address: String) async -> ApiServiceResult<String> {
        let response: ApiServiceResult<GetPublicKeyResponse> = await request { service, origin in
            await service.sendRequestJsonResponse(
                origin: origin,
                path: ApiCommands.Accounts.getPublicKey,
                method: .get,
                parameters: ["address": address],
                encoding: .url
            )
        }
        
        return response.flatMap { $0.resolved() }
    }
}
