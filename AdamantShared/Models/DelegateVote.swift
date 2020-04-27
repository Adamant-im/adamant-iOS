//
//  DelegateVote.swift
//  Adamant
//
//  Created by Anokhov Pavel on 13.07.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

enum DelegateVote {
    case upvote(publicKey: String)
    case downvote(publicKey: String)
    
    func asString() -> String {
        switch self {
        case .upvote(let key): return "+\(key)"
        case .downvote(let key): return "-\(key)"
        }
    }
}
