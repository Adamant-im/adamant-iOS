//
//  RPCResponseModel.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 29.01.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import Foundation

public struct RPCResponseModel: Codable {
    public let id: String
    public let result: Data
    
    private enum CodingKeys: String, CodingKey {
        case id
        case result
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        result = try container.decode(forKey: .result)
    }
    
    public func serialize<Response: Decodable>() -> Response? {
        try? JSONDecoder().decode(Response.self, from: result)
    }
}
