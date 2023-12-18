//
//  DashBlockchainInfoDTO.swift
//  Adamant
//
//  Created by Andrew G on 17.11.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation

struct DashBlockchainInfoDTO: Codable {
    let chain: String
    let blocks: Int
}
