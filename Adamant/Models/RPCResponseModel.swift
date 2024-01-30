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
         
         if let stringValue = try? container.decode(String.self, forKey: .result) {
             result = Data(stringValue.utf8)
         } else {
             let dictionary = try container.decode([String: Any].self, forKey: .result)
             result = try JSONSerialization.data(withJSONObject: dictionary, options: [])
         }
     }
}
