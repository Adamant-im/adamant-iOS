//
//  GetPublicKeyResponse.swift
//  Adamant
//
//  Created by Anokhov Pavel on 11.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

public final class GetPublicKeyResponse: ServerResponse {
    public let publicKey: String?
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let success = try container.decode(Bool.self, forKey: .success)
        let error = try? container.decode(String.self, forKey: .error)
        let nodeTimestamp = try container.decode(TimeInterval.self, forKey: CodingKeys.nodeTimestamp)
        self.publicKey = try? container.decode(String.self, forKey: CodingKeys.init(stringValue: "publicKey")!)
        
        super.init(success: success, error: error, nodeTimestamp: nodeTimestamp)
    }
}

// MARK: - JSON
/*
{
    "success": true,
    "publicKey": "asdasdasdasdasddasdasdasdasdasdfuckdfdsf"
}
*/
