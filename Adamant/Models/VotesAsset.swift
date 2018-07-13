//
//  VotesAsset.swift
//  Adamant
//
//  Created by Anton Boyarkin on 11/07/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

struct VotesAsset: Codable {
    let votes: [String]
	
	init(votes: [String]) {
		self.votes = votes
	}
	
	init(votes: [DelegateVote]) {
		self.votes = votes.map { $0.asString() }
	}
}
