//
//  DashNetworkInfoDTO.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 30.01.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import Foundation

struct DashNetworkInfoDTO: Codable {
    let buildversion: String
}

/*
 {
   "version": 200001,
   "buildversion": "v20.0.1",
   "subversion": "/Dash Core:20.0.1(bitcore)/",
   "protocolversion": 70230,
   "localservices": "0000000000000c05",
   "localservicesnames": [
     "NETWORK",
     "BLOOM",
     "NETWORK_LIMITED",
     "HEADERS_COMPRESSED"
   ],
   "localrelay": true,
   "timeoffset": 0,
   "networkactive": true,
   "connections": 10,
   "inboundconnections": 0,
   "outboundconnections": 10,
   "mnconnections": 8,
   "inboundmnconnections": 0,
   "outboundmnconnections": 8,
   "socketevents": "epoll",
   "networks": [
     {
       "name": "ipv4",
       "limited": false,
       "reachable": true,
       "proxy": "",
       "proxy_randomize_credentials": false
     },
     {
       "name": "ipv6",
       "limited": false,
       "reachable": true,
       "proxy": "",
       "proxy_randomize_credentials": false
     },
     {
       "name": "onion",
       "limited": true,
       "reachable": false,
       "proxy": "",
       "proxy_randomize_credentials": false
     },
     {
       "name": "i2p",
       "limited": true,
       "reachable": false,
       "proxy": "",
       "proxy_randomize_credentials": false
     }
   ],
   "relayfee": 0.00001,
   "incrementalfee": 0.00001,
   "localaddresses": [
     {
       "address": "207.180.210.95",
       "port": 9999,
       "score": 1437
     }
   ],
   "warnings": ""
 }
 */
