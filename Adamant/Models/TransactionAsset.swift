//
//  TransactionAsset.swift
//  Adamant
//
//  Created by Anokhov Pavel on 25.05.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

struct TransactionAsset: Codable {
	let chat: ChatAsset?
	let state: StateAsset?
    let votes: VotesAsset?
    
    init() {
        self.chat = nil
        self.state = nil
        self.votes = nil
    }
    
    init(chat: ChatAsset) {
        self.chat = chat
        self.state = nil
        self.votes = nil
    }
    
    init(state: StateAsset) {
        self.chat = nil
        self.state = state
        self.votes = nil
    }
    
    init(votes: VotesAsset) {
        self.chat = nil
        self.state = nil
        self.votes = votes
    }
}
