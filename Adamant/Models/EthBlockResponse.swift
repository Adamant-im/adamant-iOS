//
//  EthBlockResponse.swift
//  Adamant
//
//  Created by Владимир Клевцов on 25. 5. 2025..
//  Copyright © 2025 Adamant. All rights reserved.
//

struct EthBlockResponse: Decodable {
    let result: EthBlock?
}

struct EthBlock: Decodable {
    let timestamp: String
}
