//
//  TransactionAsset.swift
//  Adamant
//
//  Created by Anokhov Pavel on 25.05.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

public struct TransactionAsset: Codable, Hashable {
    public let chat: ChatAsset?
    public let state: StateAsset?
    public let votes: VotesAsset?
    
    public init(chat: ChatAsset? = nil, state: StateAsset? = nil, votes: VotesAsset? = nil) {
        self.chat = chat
        self.state = state
        self.votes = votes
    }
}
