//
//  IPFSNodeStatus.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 19.08.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import Foundation
import CommonKit

struct IPFSNodeStatus: Decodable {
    private enum CodingKeys: String, CodingKey {
        case version
        case timestamp
    }
    
    let height: Int
    let version: Version?
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let versionStringValue = try container.decodeIfPresent(String.self, forKey: .version)
        if let versions = versionStringValue?.components(separatedBy: ".").compactMap({ Int($0) }) {
            version = .init(versions)
        } else {
            version = nil
        }
        let timestamp = try container.decode(UInt64.self, forKey: .timestamp)
        let timeStampInSeconds = String(timestamp / 1000)
        let subString = timeStampInSeconds[
            timeStampInSeconds.index(timeStampInSeconds.startIndex, offsetBy: 2)..<timeStampInSeconds.endIndex
        ]
        let string = String(subString)
        height = Int(string) ?? .zero
    }
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
