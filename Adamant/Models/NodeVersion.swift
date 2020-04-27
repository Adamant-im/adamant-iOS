//
//  NodeVersion.swift
//  Adamant
//
//  Created by Anokhov Pavel on 21.06.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

struct NodeVersion: Codable {
    let success: Bool
    let build: String
    let commit: String
    let version: String
    let nodeTimestamp: TimeInterval
    
    var nodeDate: Date {
        return AdamantUtilities.decodeAdamant(timestamp: nodeTimestamp)
    }
}

/* JSON

{
    "success": true,
    "nodeTimestamp": 39714374,
    "build": "",
    "commit": "3b02193d470640ba841ea941f93a042095f6fc60",
    "version": "0.4.0"
}

*/
