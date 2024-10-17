//
//  NodeStatus.swift
//  Adamant
//
//  Created by Андрей on 10.05.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import Foundation

public struct NodeStatus: Codable, Sendable {
    public struct Network: Codable, Sendable {
        public let broadhash: String?
        public let epoch: String?
        public let height: Int?
        public let fee: Int?
        public let milestone: Int?
        public let nethash: String?
        public let reward: Int?
        public let supply: Int?
    }
    
    public struct Version: Codable, Sendable {
        public let build: String?
        public let commit: String?
        public let version: String?
    }
    
    public struct WsClient: Codable, Sendable {
        public let enabled: Bool?
        public let port: Int?
    }
    
    public let success: Bool
    public let nodeTimestamp: TimeInterval
    public let network: Network?
    public let version: Version?
    public let wsClient: WsClient?
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
