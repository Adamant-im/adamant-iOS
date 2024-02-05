//
//  BtcBlockchainInfoDTO.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 29.01.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import Foundation

struct BtcBlockchainInfoDTO: Decodable {
    let blocks: Int
}

/*
 {
   "chain": "main",
   "blocks": 827977,
   "headers": 827977,
   "bestblockhash": "00000000000000000003b1a332af87408df12bd88401c1c7e7456bf07786285c",
   "difficulty": 70343519904866.8,
   "mediantime": 1706537469,
   "verificationprogress": 0.9999997234436435,
   "initialblockdownload": false,
   "chainwork": "000000000000000000000000000000000000000067be7acb32fb43fafe2427e8",
   "size_on_disk": 618910285156,
   "pruned": false,
   "softforks": [
     {
       "id": "bip34",
       "version": 2,
       "reject": {
         "status": true
       }
     },
     {
       "id": "bip66",
       "version": 3,
       "reject": {
         "status": true
       }
     },
     {
       "id": "bip65",
       "version": 4,
       "reject": {
         "status": true
       }
     }
   ],
   "bip9_softforks": {
     "csv": {
       "status": "active",
       "startTime": 1462060800,
       "timeout": 1493596800,
       "since": 419328
     },
     "segwit": {
       "status": "active",
       "startTime": 1479168000,
       "timeout": 1510704000,
       "since": 481824
     }
   },
   "warnings": "Warning: unknown new rules activated (versionbit 2)"
 }
 */
