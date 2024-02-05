//
//  DashBlockchainInfoDTO.swift
//  Adamant
//
//  Created by Andrew G on 17.11.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation

struct DashBlockchainInfoDTO: Codable {
    let chain: String
    let blocks: Int
}

/*
 {
   "chain": "main",
   "blocks": 2013375,
   "headers": 2013375,
   "bestblockhash": "0000000000000017039da1b703c41b4f46cec63c49e9363e1cfb01f547bef71b",
   "difficulty": 83738861.56936724,
   "mediantime": 1706613665,
   "verificationprogress": 0.9999989398776282,
   "initialblockdownload": false,
   "chainwork": "00000000000000000000000000000000000000000000902a27ebcff9b53ae3a7",
   "size_on_disk": 36971317148,
   "pruned": false,
   "softforks": {
     "bip34": {
       "type": "buried",
       "active": true,
       "height": 951
     },
     "bip66": {
       "type": "buried",
       "active": true,
       "height": 245817
     },
     "bip65": {
       "type": "buried",
       "active": true,
       "height": 619382
     },
     "bip147": {
       "type": "buried",
       "active": true,
       "height": 939456
     },
     "csv": {
       "type": "buried",
       "active": true,
       "height": 622944
     },
     "dip0001": {
       "type": "buried",
       "active": true,
       "height": 782208
     },
     "dip0003": {
       "type": "buried",
       "active": true,
       "height": 1028160
     },
     "dip0008": {
       "type": "buried",
       "active": true,
       "height": 1088640
     },
     "dip0020": {
       "type": "buried",
       "active": true,
       "height": 1516032
     },
     "dip0024": {
       "type": "buried",
       "active": true,
       "height": 1737792
     },
     "realloc": {
       "type": "buried",
       "active": true,
       "height": 1374912
     },
     "v19": {
       "type": "buried",
       "active": true,
       "height": 1899072
     },
     "v20": {
       "type": "bip9",
       "bip9": {
         "status": "active",
         "start_time": 1700006400,
         "timeout": 1731628800,
         "ehf": false,
         "since": 1987776
       },
       "height": 1987776,
       "active": true
     },
     "mn_rr": {
       "type": "bip9",
       "bip9": {
         "status": "defined",
         "start_time": 1704067200,
         "timeout": 1767225600,
         "ehf": true,
         "since": 0
       },
       "active": false
     }
   },
   "warnings": ""
 }
 */
