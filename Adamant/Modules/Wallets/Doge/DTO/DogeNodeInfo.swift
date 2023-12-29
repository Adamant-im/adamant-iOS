//
//  DogeInfoResponce.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 27.12.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation

struct DogeNodeInfo: Decodable {
    struct Info: Decodable {
        let version: Int
        let protocolversion: Int
        let blocks: Int
    }
    
    let info: Info
}

/*
 {
     "info": {
         "version": 1140200,
         "protocolversion": 70015,
         "blocks": 5025989,
         "timeoffset": -1,
         "connections": 10,
         "proxy": "",
         "difficulty": 10181073.49074949,
         "testnet": false,
         "paytxfee": 0,
         "relayfee": 1,
         "errors": ""
     }
 }
 */
