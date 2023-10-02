//
//  BtcUnspentTransactionResponse.swift
//  Adamant
//
//  Created by Anton Boyarkin on 10.05.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import Foundation

struct BtcUnspentTransactionResponse: Decodable {
    enum CodingKeys: String, CodingKey {
        case txId = "txid"
        case vout
        case value
        case status
    }
    
    let txId: String
    let vout: UInt32
    let value: Decimal
    let status: RawBtcStatus
}
