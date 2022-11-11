//
//  BtcBalanceResponse.swift
//  Adamant
//
//  Created by Anton Boyarkin on 10.05.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import Foundation

struct BtcBalanceResponse: Decodable {
    enum CodingKeys: String, CodingKey {
        case address
        case stats = "chain_stats"
    }

    let address: String
    let stats: ChainStats
}

extension BtcBalanceResponse {
    var value: Decimal {
        return stats.funded - stats.spent
    }
}

struct ChainStats: Decodable {
    enum CodingKeys: String, CodingKey {
        case funded = "funded_txo_sum"
        case spent = "spent_txo_sum"
    }

    let funded: Decimal
    let spent: Decimal
}
