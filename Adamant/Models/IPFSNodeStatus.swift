//
//  IPFSNodeStatus.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 19.08.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import Foundation

struct IPFSNodeStatus: Codable {
    let version: String
}

/* JSON

 {
    "version":"0.0.1",
    "timestamp":1724085764840,
    "heliaStatus":"started",
    "peerId":"12D3KooWGMp6SaKon2UKwJsDEf3chLAGRzsjdAfDGN9zcwt6ydqJ",
    "multiAddresses":[
       "/ip4/127.0.0.1/tcp/4001/p2p/12D3KooWGMp6SaKon2UKwJsDEf3chLAGRzsjdAfDGN9zcwt6ydqJ",
       "/ip4/95.216.45.88/tcp/4001/p2p/12D3KooWGMp6SaKon2UKwJsDEf3chLAGRzsjdAfDGN9zcwt6ydqJ"
    ],
    "blockstoreSizeMb":5053.823321342468,
    "datastoreSizeMb":0.135406494140625,
    "availableSizeInMb":943942
 }

*/
