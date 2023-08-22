//
//  EmojiService.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 14.07.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation

protocol EmojiService: AnyObject {
    func getFrequentlySelectedEmojis() -> [String]
    func updateFrequentlySelectedEmojis(
        selectedEmoji: String,
        type: EmojiUpdateType
    )
}
