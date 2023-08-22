//
//  Reaction.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 11.07.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation

struct Reaction: Equatable, Hashable, Codable {
    let sender: String
    let reaction: String?
    let sentDate: Date
}
