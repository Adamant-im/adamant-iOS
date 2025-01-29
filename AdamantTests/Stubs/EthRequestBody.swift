//
//  EthRequestBody.swift
//  Adamant
//
//  Created by Christian Benua on 16.01.2025.
//  Copyright © 2025 Adamant. All rights reserved.
//

import Web3Core

struct EthRequestBody: Decodable {
    var method: String
    var params: [Any]
    
    enum CodingKeys: String, CodingKey {
        case method
        case params
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.method = try container.decode(String.self, forKey: .method)
        self.params = try container.decode([Any].self, forKey: .params)
    }
}
