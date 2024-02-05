//
//  BtcNetworkInfoDTO.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 29.01.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import Foundation

struct BtcNetworkInfoDTO: Decodable {
    let version: Int
}

/*
 {
   "version": 180100,
   "subversion": "/Satoshi:0.18.1/",
   "protocolversion": 70015,
   "localservices": "000000000000040d",
   "localrelay": true,
   "timeoffset": -10,
   "networkactive": true,
   "connections": 124,
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
     }
   ],
   "relayfee": 0.00001,
   "incrementalfee": 0.00001,
   "localaddresses": [
     {
       "address": "176.9.38.204",
       "port": 8333,
       "score": 207494
     },
     {
       "address": "2a01:4f8:150:44d4::2",
       "port": 8333,
       "score": 80610
     }
   ],
   "warnings": "Warning: unknown new rules activated (versionbit 2)"
 }
 */
