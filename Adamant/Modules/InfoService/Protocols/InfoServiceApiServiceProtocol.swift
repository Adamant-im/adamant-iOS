//
//  InfoServiceApiServiceProtocol.swift
//  Adamant
//
//  Created by Andrew G on 23.08.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import Foundation
import CommonKit

protocol InfoServiceApiServiceProtocol: ApiServiceProtocol {
    func loadRates(
        coins: [String]
    ) async -> InfoServiceApiResult<[InfoServiceTicker: Decimal]>
    
    func getHistory(
        coin: String,
        date: Date
    ) async -> InfoServiceApiResult<InfoServiceHistoryItem>
}
