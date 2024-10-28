//
//  InfoServiceApiService+Extension.swift
//  Adamant
//
//  Created by Andrew G on 24.08.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import Foundation
import CommonKit

extension InfoServiceApiService: ApiServiceProtocol {
    var chosenFastestNodeId: UUID? {
        get async { await core.chosenNodeId }
    }
    
    func healthCheck() {
        Task { await core.healthCheck() }
    }
    
    var hasActiveNode: Bool {
        get async { await !core.sortedAllowedNodes.isEmpty }
    }
}

extension InfoServiceApiService: InfoServiceApiServiceProtocol {
    func loadRates(
        coins: [String]
    ) async -> InfoServiceApiResult<[InfoServiceTicker: Decimal]> {
        await request { core, origin in
            await core.sendRequestJsonResponse(
                origin: origin,
                path: InfoServiceApiCommands.get,
                method: .get,
                parameters: mapper.mapToRatesRequestDTO(coins),
                encoding: .url
            )
        }.flatMap { mapper.mapRatesToModel($0) }
    }
    
    func getHistory(
        coin: String,
        date: Date
    ) async -> InfoServiceApiResult<InfoServiceHistoryItem> {
        await request { core, origin in
            await core.sendRequestJsonResponse(
                origin: origin,
                path: InfoServiceApiCommands.getHistory,
                method: .get,
                parameters: mapper.mapToHistoryRequestDTO(date: date, coin: coin),
                encoding: .url
            )
        }.flatMap { mapper.mapToModel($0) }
    }
}
