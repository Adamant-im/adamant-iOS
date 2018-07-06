//
//  File.swift
//  Adamant
//
//  Created by Anton Boyarkin on 06/07/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

struct Delegate: Decodable {
    let username: String
    let address: String
    let publicKey: String
    let vote: String
    let producedblocks: Int
    let missedblocks: Int
    let rate: Int
    let rank: Int
    let approval: Float
    let productivity: Float
}

extension Delegate: WrappableModel {
    static let ModelKey = "delegate"
}

extension Delegate: WrappableCollection {
    static let CollectionKey = "delegates"
}

/*
{
    "username":"road",
    "address":"U8607002570607148960",
    "publicKey":"1aaf9368a3d67708cf9d9e8045d71c29f98fdd796aa30a7c5296324f342a5aa2",
    "vote":"99650461184861",
    "producedblocks":38642,
    "missedblocks":176,
    "rate":1,
    "rank":1,
    "approval":1.01,
    "productivity":99.55
}
*/
