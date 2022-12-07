//
//  VotesAsset.swift
//  Adamant
//
//  Created by Anton Boyarkin on 11/07/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

struct VotesAsset: Hashable {
    let votes: [String]
    
    init(votes: [String]) {
        self.votes = votes
    }
    
    init(votes: [DelegateVote]) {
        self.votes = votes.map { $0.asString() }
    }
}

extension VotesAsset: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.votes = try container.decode([String].self)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(votes)
    }
}
