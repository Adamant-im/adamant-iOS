//
//  NodeStatus.swift
//  Adamant
//
//  Created by Андрей on 10.05.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import Foundation

struct NodeStatus: Codable {
    struct Network: Codable {
        let broadhash: String?
        let epoch: String?
        let height: Int?
        let fee: Int?
        let milestone: Int?
        let nethash: String?
        let reward: Int?
        let supply: Int?
    }
    
    struct Version: Codable {
        let build: String?
        let commit: String?
        let version: String?
    }
    
    struct WsClient: Codable {
        let enabled: Bool?
        let port: Int?
    }
    
    let success: Bool
    let nodeTimestamp: TimeInterval
    let network: Network?
    let version: Version?
    let wsClient: WsClient?
}

/* JSON

 {
    "success":true,
    "nodeTimestamp":147836123,
    "network":{
       "broadhash":"95c1148ec9a88f954068b3ee4e38cd6e069fcafb3da3ebdc311ea96dd3ac052f",
       "epoch":"2017-09-02T17:00:00.000Z",
       "height":27808997,
       "fee":50000000,
       "milestone":4,
       "nethash":"bd330166898377fb28743ceef5e43a5d9d0a3efd9b3451fb7bc53530bb0a6d64",
       "reward":30000000,
       "supply":10889269940000000
    },
    "version":{
       "build":"",
       "commit":"fef0c69a8a83c58b7ca5e3e4cda545cc1c61cb23",
       "version":"0.6.0"
    },
    "wsClient":{
       "enabled":true,
       "port":36668
    }
 }

*/
