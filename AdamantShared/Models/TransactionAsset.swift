//
//  TransactionAsset.swift
//  Adamant
//
//  Created by Anokhov Pavel on 25.05.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

struct TransactionAsset: Codable, Hashable {
    let chat: ChatAsset?
    let state: StateAsset?
    let votes: VotesAsset?
    
    init() {
        self.chat = nil
        self.state = nil
        self.votes = nil
    }
    
    init(chat: ChatAsset? = nil, state: StateAsset? = nil, votes: VotesAsset? = nil) {
        self.chat = chat
        self.state = state
        self.votes = votes
    }
}
