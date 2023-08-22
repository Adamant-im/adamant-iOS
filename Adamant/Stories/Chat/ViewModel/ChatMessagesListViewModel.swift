//
//  ChatMessagesListViewModel.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 14.07.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation

final class ChatMessagesListViewModel {
    // MARK: Dependencies
    
    let avatarService: AvatarService
    let emojiService: EmojiService
    
    init(
        avatarService: AvatarService,
        emojiService: EmojiService
    ) {
        self.avatarService = avatarService
        self.emojiService = emojiService
    }
}
