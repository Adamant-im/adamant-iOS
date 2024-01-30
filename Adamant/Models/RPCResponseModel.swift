//
//  RPCResponseModel.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 29.01.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import Foundation

struct RPCResponseModel: Codable {
    let id: String
    let result: Data
    
    private enum CodingKeys: String, CodingKey {
         case id
         case result
     }

     init(from decoder: Decoder) throws {
         let container = try decoder.container(keyedBy: CodingKeys.self)
         id = try container.decode(String.self, forKey: .id)
         result = try container.decode(forKey: .result)
     }
}
